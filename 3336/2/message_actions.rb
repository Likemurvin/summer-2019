# Module that stores all the actions for telegram bot
module Actions
  def start(bot, message)
    bot.api.send_message(chat_id: message.chat.id,
                         text: "Hello, #{message.from.first_name}, please give me ur rubizza id")
    @user_state = 'id_check'
  end

  def id_check(bot, message, redis)
    if students_ids.include?(message.text)
      if redis.get('student_id') != message.to_s
        if @user_state == 'id_check'
          bot.api.send_message(chat_id: message.chat.id,
                               text: "I know that ID - #{message}, now u can checkin")
          @user_state = 'checkin'
          redis.set('student_id', message.to_s)
          redis.set('telegram_id', message.chat.id.to_s)
          p redis.get('student_id')
          p redis.get('telegram_id')
        else
          bot.api.send_message(chat_id: message.chat.id,
                               text: error_msg)
        end
      elsif
        redis.get('student_id') == message.to_s
        bot.api.send_message(chat_id: message.chat.id,
                             text: 'You are already sign, try to checkout first')
      else
        bot.api.send_message(chat_id: message.chat.id,
                             text: error_msg)
      end
    end
  end

  def checkin(bot, message)
    if @user_state == 'checkin'
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Take a selfie!')
      @user_state = 'photo_check'
    else
      bot.api.send_message(chat_id: message.chat.id,
                           text: error_msg)
    end
  end

  def checkout(bot, message)
    if @user_state == 'checkout'
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Take a "bye" selfie')
      @user_state = 'photo_checkout'
    else
      bot.api.send_message(chat_id: message.chat.id,
                           text: error_msg)
    end
  end

  def photo_check(bot, message, token)
    if @user_state == 'photo_check'
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Nice! Now share your location')
      path = bot.api.get_file(chat_id: message.chat.id,
                              file_id: message.photo.last.file_id)['result']['file_path']
      Down.download("https://api.telegram.org/file/bot#{token}/#{path}",
                    destination: './data/checkin/')
      @user_state = 'geo_check'
    elsif @user_state == 'photo_checkout'
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'Share your location')
      path = bot.api.get_file(chat_id: message.chat.id,
                              file_id: message.photo.last.file_id)['result']['file_path']
      Down.download("https://api.telegram.org/file/bot#{token}/#{path}",
                    destination: './data/checkout/')
      @user_state = 'geo_checkout'
    else
      bot.api.send_message(chat_id: message.chat.id,
                           text: error_msg)
    end
  end

  def geo_check(bot, message, redis)
    if @user_state == 'geo_check'
      bot.api.send_message(chat_id: message.chat.id,
                           text: "You succsesfully check'd, good luck! Don't forget to checkout")
      p message.location
      @user_state = 'checkout'
    elsif @user_state == 'geo_checkout'
      bot.api.send_message(chat_id: message.chat.id,
                           text: 'You succsesfully checkout, hope to see you tomorrow!')
      @user_state = 'start'
    else
      bot.api.send_message(chat_id: message.chat.id,
                           text: error_msg)
    end
  end
end
