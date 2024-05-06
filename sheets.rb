require 'telegram/bot'
require 'dotenv/load'
require 'google_drive'

TELEGRAM_BOT_TOKEN = ENV.fetch('TELEGRAM_BOT_TOKEN')
class GoogleService
  def initialize
    @spreadsheet = GoogleDrive::Session.from_service_account_key('key.json')
                                       .file_by_id('1m6EG7ipOFwYoMNI1fZTaUc9fRpAeSGDcW4QMo5dqgDc')
  end

  def worksheet(try=1)
    @spreadsheet.worksheets.first
  rescue
    try += 1
    sleep 2 * try
    retry if try <= 5
    raise
  end

  def all_word
    worksheet.rows.map { |i| i.first }.join("\n")
  end

  def write(**options)
    total_rows = worksheet.num_rows
    new_row    = total_rows + 1

    worksheet.rows.each { |row| return 'Слово уже существует' if row.first.include?(options[:word]) }

    current_sheet = worksheet
    current_sheet[new_row, 1] = options[:word]
    current_sheet.save
    nil
  end
end

g_service = GoogleService.new

Telegram::Bot::Client.run(TELEGRAM_BOT_TOKEN) do |bot|
  bot.listen do |message|
    if message.text
      if message.text.match?(/\A[Aa]dd [a-zA-Z\W][a-zA-Z\W]/)
        word   = message.text.sub(/\A[Aa]dd /, '')
        result = g_service.write(word: word)
        msg    = result.nil? ? "Cлово '#{word}' успешно сохранено" : result
        bot.api.send_message(chat_id: message.chat.id, text: msg, parse_mode: 'MarkdownV2')
      elsif message.text.match?(/\A[Aa]ll ?\z/)
        msg = g_service.all_word
        msg = msg != '' ? msg : "Нет сохраненых слов"
        bot.api.send_message(chat_id: message.chat.id, text: msg, parse_mode: 'MarkdownV2')
      else
        bot.api.send_message(chat_id: message.chat.id,
                             text: 'Введи All или Add и через пробел сохраняемое слово', parse_mode: 'MarkdownV2')
      end
    else 
      bot.api.send_message(chat_id: message.chat.id, text: "Не верные данные!\n#{message.text}",
                           parse_mode: 'MarkdownV2')
    end
  end
end
