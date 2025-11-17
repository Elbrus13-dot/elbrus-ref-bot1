import os
from telegram import Bot, Update, ReplyKeyboardMarkup
from telegram.ext import Application, CommandHandler, MessageHandler, filters
from apscheduler.schedulers.background import BackgroundScheduler

BOT_TOKEN = os.getenv("BOT_TOKEN")

async def start(update: Update, context):
    keyboard = [["💡 Советы", "📞 Связаться"], ["ℹ️ О проекте"]]
    reply_markup = ReplyKeyboardMarkup(keyboard, resize_keyboard=True)
    await update.message.reply_text("Привет! Я бот Эльбруса. Выберите действие:", reply_markup=reply_markup)

async def message_handler(update: Update, context):
    text = update.message.text
    if text == "💡 Советы":
        await update.message.reply_text("Совет дня: не сдавайся 💪")
    elif text == "📞 Связаться":
        await update.message.reply_text("Связь: @elbrustyle")
    elif text == "ℹ️ О проекте":
        await update.message.reply_text("Это бот для автоматизации арбитража.")
    else:
        await update.message.reply_text("Я не понял. Выберите кнопку.")

def send_daily_tip():
    bot = Bot(BOT_TOKEN)
    chat_id = os.getenv("CHAT_ID")
    if chat_id:
        bot.send_message(chat_id=chat_id, text="🔥 Ежедневный совет: будь на шаг впереди!")

def main():
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, message_handler))

    scheduler = BackgroundScheduler()
    scheduler.add_job(send_daily_tip, "interval", hours=24)
    scheduler.start()

    app.run_polling()

if __name__ == "__main__":
    main()
