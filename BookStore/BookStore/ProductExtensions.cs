using System;

namespace BookStore // ВАЖНО: Пространство имен должно совпадать с тем, что сгенерировал EDMX (обычно это BookStore или BookstoreWPF)
{
    // Расширяем сгенерированный класс Product
    public partial class Product
    {
        // Итоговая цена с учетом скидки
        public decimal FinalPrice
        {
            get
            {
                decimal discount = this.Discount ?? 0;
                return this.Price * (1 - (discount / 100));
            }
        }

        // Есть ли скидка вообще
        public bool IsDiscounted
        {
            get { return (this.Discount ?? 0) > 0; }
        }
    }
}