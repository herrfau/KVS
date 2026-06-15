using Microsoft.VisualStudio.TestTools.UnitTesting;
using BookStore; // Подключаем наш основной проект

namespace BookstoreWPF.Tests
{
    [TestClass]
    public class ValidationHelperTests
    {
        // ==========================================
        // ТЕСТЫ ДЛЯ ЦЕНЫ
        // ==========================================

        [TestMethod]
        public void IsPriceValid_PositiveNumber_ReturnsTrue()
        {
            // Arrange (Подготовка)
            string input = "1500,50";

            // Act (Действие)
            bool result = ValidationHelper.IsPriceValid(input, out decimal price);

            // Assert (Проверка)
            Assert.IsTrue(result, "Цена 1500,50 должна быть валидной");
            Assert.AreEqual(1500.50m, price, "Распознанное число должно совпадать");
        }

        [TestMethod]
        public void IsPriceValid_Zero_ReturnsTrue()
        {
            bool result = ValidationHelper.IsPriceValid("0", out _);
            Assert.IsTrue(result, "Цена 0 допустима");
        }

        [TestMethod]
        public void IsPriceValid_NegativeNumber_ReturnsFalse()
        {
            bool result = ValidationHelper.IsPriceValid("-100", out _);
            Assert.IsFalse(result, "Отрицательная цена должна отклоняться");
        }

        [TestMethod]
        public void IsPriceValid_Text_ReturnsFalse()
        {
            bool result = ValidationHelper.IsPriceValid("Бесплатно", out _);
            Assert.IsFalse(result, "Текст вместо числа должен отклоняться");
        }

        // ==========================================
        // ТЕСТЫ ДЛЯ ОСТАТКА НА СКЛАДЕ
        // ==========================================

        [TestMethod]
        public void IsStockValid_PositiveInteger_ReturnsTrue()
        {
            bool result = ValidationHelper.IsStockValid("15", out decimal stock);
            Assert.IsTrue(result);
            Assert.AreEqual(15m, stock);
        }

        [TestMethod]
        public void IsStockValid_Negative_ReturnsFalse()
        {
            bool result = ValidationHelper.IsStockValid("-5", out _);
            Assert.IsFalse(result, "Отрицательный остаток недопустим");
        }

        // ==========================================
        // ТЕСТЫ ДЛЯ СКИДКИ
        // ==========================================

        [TestMethod]
        public void IsDiscountValid_WithinRange_ReturnsTrue()
        {
            bool result = ValidationHelper.IsDiscountValid("15,5", out _);
            Assert.IsTrue(result, "Скидка 15,5% должна быть валидной");
        }

        [TestMethod]
        public void IsDiscountValid_MaxLimit_ReturnsTrue()
        {
            bool result = ValidationHelper.IsDiscountValid("99,99", out _);
            Assert.IsTrue(result, "Максимальная граница 99,99 должна проходить");
        }

        [TestMethod]
        public void IsDiscountValid_Over100_ReturnsFalse()
        {
            bool result = ValidationHelper.IsDiscountValid("100", out _);
            Assert.IsFalse(result, "Скидка 100% и более должна отклоняться");
        }

        [TestMethod]
        public void IsDiscountValid_Negative_ReturnsFalse()
        {
            bool result = ValidationHelper.IsDiscountValid("-5", out _);
            Assert.IsFalse(result, "Отрицательная скидка недопустима");
        }
    }
}