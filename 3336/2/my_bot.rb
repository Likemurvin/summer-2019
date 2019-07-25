require 'telegram/bot'
require 'rubygems'
require 'redis'
require 'down'
require 'yaml'
require_relative 'message_actions.rb'

token = gets.chomp
redis = Redis.new

class Bot
  include Actions
  def students_ids
    YAML.load_file('./data/student_id.yaml')["students_id's"]
  end

  def error_msg
    "Please, follow instructions, now you are on the #{@user_state} state"
  end

  def bot_message(bot, message, text)
    bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def run_bot(token, redis)
    @user_state = 'start'
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        if message.text
          if message.text == '/start'
            start(bot, message)
          elsif message.text.to_i.positive?
            id_check(bot, message, redis)
          elsif message.text == '/checkin'
            checkin(bot, message)
          elsif message.text == '/checkout'
            checkout(bot, message)
          else
            bot.api.send_message(chat_id: message.chat.id,
                                 text: error_msg)
          end
        end
        if message.photo.any?
          photo_check(bot, message, token)
        elsif message.location
          geo_check(bot, message, redis)
        end
      end
    end
  end
end

Bot.new.run_bot(token, redis)
