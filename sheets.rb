require 'telegram/bot'
require 'dotenv/load'
require 'google_drive'
require 'pry'

TELEGRAM_BOT_TOKEN = ENV.fetch('TELEGRAM_BOT_TOKEN')

def connect_sheet
  session     = GoogleDrive::Session.from_service_account_key('key.json')
  spreadsheet = session.file_by_id('1m6EG7ipOFwYoMNI1fZTaUc9fRpAeSGDcW4QMo5dqgDc')
  spreadsheet.worksheets.first
end

def all_word
  connect_sheet.rows.map { |i| i.first }.join("\n")
end

def write(**options)
  worksheet  = connect_sheet
  total_rows = worksheet.num_rows
  new_row = total_rows + 1

  worksheet.rows.each { |row| return 'Слово уже существует!' if row.first.include?(options[:word]) }

  worksheet[new_row, 1] = options[:word]
  worksheet.save
  nil
end

Telegram::Bot::Client.run(TELEGRAM_BOT_TOKEN) do |bot|
  bot.listen do |message|
    if message.text
      if message.text.match?(/\A[Aa]dd [a-zA-Z\W][a-zA-Z\W]/)
        word = message.text.sub(/\A[Aa]dd /, '')
        result = write(word: word)
        msg = result.nil? ? "Cлово '#{word}' успешно сохранено" : result
        bot.api.send_message(chat_id: '1760823856', text: msg, parse_mode: 'MarkdownV2')
        nil
      elsif message.text.match?(/\A[Aa]ll ?\z/)
        msg = all_word
        msg = msg != '' ? msg : "Нет сохраненых слов"
        bot.api.send_message(chat_id: message.chat.id, text: msg, parse_mode: 'MarkdownV2')
        nil
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'Введи All или Add и через пробел сохраняемое слово', parse_mode: 'MarkdownV2')
        nil
      end
    else 
      bot.api.send_message(chat_id: '1760823856', text: "Не верные данные!\n#{message.text}", parse_mode: 'MarkdownV2')
    end
  end
end
