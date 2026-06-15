using System;

namespace BookstoreWPF
{
    public static class ValidationHelper
    {
        // Проверка цены: должна быть числом и >= 0
        public static bool IsPriceValid(string input, out decimal price)
        {
            bool isNumber = decimal.TryParse(input, out price);
            return isNumber && price >= 0;
        }

        // Проверка остатка: должно быть числом и >= 0
        public static bool IsStockValid(string input, out decimal stock)
        {
            bool isNumber = decimal.TryParse(input, out stock);
            return isNumber && stock >= 0;
        }

        // Проверка скидки: число от 0 до 99.99
        public static bool IsDiscountValid(string input, out decimal discount)
        {
            bool isNumber = decimal.TryParse(input, out discount);
            return isNumber && discount >= 0 && discount <= 99.99m;
        }
    }
}