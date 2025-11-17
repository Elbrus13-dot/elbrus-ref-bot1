import os
import sqlite3
from telegram import (
    Update, ReplyKeyboardMarkup, LabeledPrice
)
from telegram.ext import (
    Application, CommandHandler, MessageHandler, filters,
    PreCheckoutQueryHandler
)
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime

BOT_TOKEN = os.getenv("BOT_TOKEN")
PAYMENT_TOKEN = os.getenv("PAYMENT_TOKEN")
ADMIN_ID = int(os.getenv("ADMIN_ID", "123456789"))  # замени на свой Telegram ID
DB_PATH = "payments.db"

# Инициализация базы
def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS payments (
        user_id INTEGER,
        amount INTEGER,
        timestamp TEXT
    )""")
    conn.commit()
    conn.close()

# Приветствие
async def start(update: Update, context):
    user = update.effective_user
    name = user.first_name or "друг"
    keyboard = [
        ["💬 Платный чат", "📞 Консультация"],
        ["🤝 Партнерская программа", "📨 Связаться"],
        ["👤 Профиль", "💳 Оплатить"]
    ]
    reply_markup = ReplyKeyboardMarkup(keyboard, resize_keyboard=True)
    await update.message.reply_text(f"Привет, {name}! Я бот Эльбруса. Выберите действие:", reply_markup=reply_markup)

# Обработка кнопок
async def message_handler(update: Update, context):
    text = update.message.text
    if text == "💬 Платный чат":
        await update.message.reply_text("🔐 Доступ к платному чату: @elbrustyle")
    elif text == "📞 Консультация":
        await update.message.reply_text("📲 Запись: @konsalting13_bot")
    elif text == "🤝 Партнерская программа":
        await update.message.reply_text("💼 Условия: напиши @elbrustyle")
    elif text == "📨 Связаться":
        await update.message.reply_text("📬 Связь: @elbrustyle")
    elif text == "👤 Профиль":
        await update.message.reply_text("👤 Ваш профиль: скоро будет доступен.")
    elif text == "💳 Оплатить":
        prices = [LabeledPrice("Доступ в VIP чат", 50000)]  # 500 руб
        await context.bot.send_invoice(
            chat_id=update.effective_chat.id,
            title="VIP доступ",
            description="После оплаты вы получите доступ",
            payload="chat-access",
            provider_token=PAYMENT_TOKEN,
            currency="RUB",
            prices=prices,
            start_parameter="access"
        )
    else:
        await update.message.reply_text("Я не понял. Выберите кнопку.")

# Проверка перед оплатой
async def precheckout_callback(update: Update, context):
    query = update.pre_checkout_query
    if query.invoice_payload != "chat-access":
        await query.answer(ok=False, error_message="Неверный платёж.")
    else:
        await query.answer(ok=True)

# Успешная оплата
async def successful_payment(update: Update, context):
    user_id = update.effective_user.id
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("INSERT INTO payments VALUES (?, ?, ?)", (
        user_id, 500, datetime.now().isoformat()
    ))
    conn.commit()
    conn.close()
    await update.message.reply_text("✅ Оплата прошла! Доступ открыт.")

# Автопрогрев
def send_daily_tip():
    bot = Application.builder().token(BOT_TOKEN).build().bot
    chat_id = os.getenv("CHAT_ID")
    if chat_id:
        bot.send_message(chat_id=int(chat_id), text="🔥 Совет дня: будь на шаг впереди!")

# Админка
async def admin_panel(update: Update, context):
    if update.effective_user.id != ADMIN_ID:
        return
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT COUNT(*), SUM(amount) FROM payments")
    count, total = c.fetchone()
    conn.close()
    await update.message.reply_text(f"💰 Доход: {total or 0}₽\n👥 Оплатили: {count} человек")

# Запуск
def main():
    init_db()
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("admin", admin_panel))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, message_handler))
    app.add_handler(PreCheckoutQueryHandler(precheckout_callback))
    app.add_handler(MessageHandler(filters.SUCCESSFUL_PAYMENT, successful_payment))

    scheduler = BackgroundScheduler()
    scheduler.add_job(send_daily_tip, "interval", hours=24)
    scheduler.start()

    app.run_polling()

if __name__ == "__main__":
    main()
