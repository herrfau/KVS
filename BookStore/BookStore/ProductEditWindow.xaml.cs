using BookStore;
using BookstoreWPF;
using Microsoft.Win32;
using System;
using System.Data;
using System.Data.Entity;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Windows;
using System.Windows.Media.Imaging;
using System.Xml.Linq;

namespace BookStore
{
    public partial class ProductEditWindow : Window
    {
        private static ProductEditWindow _instance; // Защита от двойного открытия
        private Product _currentProduct;
        private MainWindow _mainWindow;
        private string _originalPhotoPath; // Запоминаем старое фото для удаления

        public ProductEditWindow(Product product, MainWindow mainWindow)
        {
            // Проверка: если окно уже открыто, фокусируемся на нем и прерываем создание нового
            if (_instance != null && _instance != this)
            {
                _instance.Focus();
                throw new Exception("Окно редактирования уже открыто. Закройте его, чтобы редактировать другой товар.");
            }

            InitializeComponent();
            _instance = this;
            _mainWindow = mainWindow;

            LoadComboBoxes();

            if (product != null)
            {
                // --- РЕЖИМ РЕДАКТИРОВАНИЯ ---
                Title = "Редактирование товара";
                _currentProduct = product;
                _originalPhotoPath = product.Photo;

                TxtId.Text = product.Id.ToString();
                TxtId.Visibility = Visibility.Visible;
                TxtIdPlaceholder.Visibility = Visibility.Collapsed;

                TxtArticle.Text = product.Article;
                TxtName.Text = product.Name;
                TxtDescription.Text = product.Description;
                TxtPrice.Text = product.Price.ToString();
                TxtStock.Text = product.AmountInStock.ToString();
                TxtDiscount.Text = (product.Discount ?? 0).ToString();

                // Привязка выбранных значений в ComboBox
                CmbCategory.SelectedValue = product.CategoryId;
                CmbProducer.SelectedValue = product.ProducerId;
                CmbProvider.SelectedValue = product.ProviderId;
                CmbUnit.SelectedValue = product.UnitId;

                ImgProduct.DataContext = product; // Биндинг фото
                BtnDelete.Visibility = Visibility.Visible; // Показываем кнопку удаления
            }
            else
            {
                // --- РЕЖИМ ДОБАВЛЕНИЯ ---
                Title = "Добавление нового товара";
                _currentProduct = new Product();
                ImgProduct.DataContext = _currentProduct;
            }
        }

        private void LoadComboBoxes()
        {
            try
            {
                using (var db = new db_bookstoreEntities())
                {
                    CmbCategory.ItemsSource = db.Category.ToList();
                    CmbProducer.ItemsSource = db.Producer.ToList();
                    CmbProvider.ItemsSource = db.Provider.ToList();
                    CmbUnit.ItemsSource = db.Unit.ToList();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка загрузки справочников:\n" + ex.Message, "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void BtnUploadPhoto_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new OpenFileDialog();
            dlg.Filter = "Изображения|*.jpg;*.jpeg;*.png;*.bmp";
            if (dlg.ShowDialog() == true)
            {
                try
                {
                    string destDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Images");
                    if (!Directory.Exists(destDir)) Directory.CreateDirectory(destDir);

                    string fileName = Guid.NewGuid().ToString() + ".jpg";
                    string destPath = Path.Combine(destDir, fileName);

                    // Сжатие до 300x200
                    ResizeImage(dlg.FileName, destPath, 300, 200);

                    // Обновляем путь и перезагружаем картинку в UI
                    _currentProduct.Photo = destPath;
                    ImgProduct.DataContext = null;
                    ImgProduct.DataContext = _currentProduct;
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Не удалось обработать изображение:\n" + ex.Message, "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private void ResizeImage(string inputPath, string outputPath, int width, int height)
        {
            using (Image img = Image.FromFile(inputPath))
            {
                using (Bitmap bmp = new Bitmap(width, height))
                {
                    using (Graphics g = Graphics.FromImage(bmp))
                    {
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.DrawImage(img, 0, 0, width, height);
                    }
                    bmp.Save(outputPath, System.Drawing.Imaging.ImageFormat.Jpeg);
                }
            }
        }

        private void BtnSave_Click(object sender, RoutedEventArgs e)
        {
            // 1. ВАЛИДАЦИЯ
            if (string.IsNullOrWhiteSpace(TxtArticle.Text) || string.IsNullOrWhiteSpace(TxtName.Text))
            {
                MessageBox.Show("Артикул и Наименование обязательны для заполнения!", "Ошибка ввода", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (!ValidationHelper.IsPriceValid(TxtPrice.Text, out decimal price))
            {
                MessageBox.Show("Цена должна быть числом и не может быть отрицательной!", "Ошибка ввода", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (!ValidationHelper.IsStockValid(TxtStock.Text, out decimal stock))
            {
                MessageBox.Show("Количество на складе должно быть числом и не может быть отрицательным!", "Ошибка ввода", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (!ValidationHelper.IsDiscountValid(TxtDiscount.Text, out decimal discount))
            {
                MessageBox.Show("Скидка должна быть числом от 0 до 99.99!", "Ошибка ввода", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (CmbCategory.SelectedValue == null || CmbProducer.SelectedValue == null || CmbProvider.SelectedValue == null || CmbUnit.SelectedValue == null)
            {
                MessageBox.Show("Пожалуйста, выберите категорию, производителя, поставщика и единицу измерения!", "Ошибка ввода", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            // 2. СОХРАНЕНИЕ В БД
            try
            {
                using (var db = new db_bookstoreEntities())
                {
                    _currentProduct.Article = TxtArticle.Text;
                    _currentProduct.Name = TxtName.Text;
                    _currentProduct.Description = TxtDescription.Text;
                    _currentProduct.Price = price;
                    _currentProduct.AmountInStock = stock;
                    _currentProduct.Discount = discount;

                    _currentProduct.CategoryId = (int)CmbCategory.SelectedValue;
                    _currentProduct.ProducerId = (int)CmbProducer.SelectedValue;
                    _currentProduct.ProviderId = (int)CmbProvider.SelectedValue;
                    _currentProduct.UnitId = (int)CmbUnit.SelectedValue;

                    if (_currentProduct.Id == 0)
                        db.Product.Add(_currentProduct); // Добавление
                    else
                        db.Entry(_currentProduct).State = EntityState.Modified; // Редактирование

                    db.SaveChanges();
                }

                // 3. Удаление старого фото с диска, если оно было заменено
                if (!string.IsNullOrEmpty(_originalPhotoPath) && _originalPhotoPath != _currentProduct.Photo)
                {
                    if (File.Exists(_originalPhotoPath))
                    {
                        try { File.Delete(_originalPhotoPath); } catch { }
                    }
                }

                MessageBox.Show("Товар успешно сохранен!", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);

                _mainWindow.RefreshProducts(); // Обновляем список в MainWindow
                CloseWindow();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка при сохранении в базу данных:\n" + ex.Message, "Критическая ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void BtnDelete_Click(object sender, RoutedEventArgs e)
        {
            if (_currentProduct == null || _currentProduct.Id == 0) return;

            MessageBoxResult result = MessageBox.Show(
                $"Вы уверены, что хотите удалить товар \"{_currentProduct.Name}\"?\nЭто действие необратимо.",
                "Подтверждение удаления",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (result == MessageBoxResult.Yes)
            {
                try
                {
                    using (var db = new db_bookstoreEntities())
                    {
                        // ПРОВЕРКА: Есть ли товар в заказах?
                        bool isInOrders = db.ProductInOrder.Any(p => p.ProductId == _currentProduct.Id);

                        if (isInOrders)
                        {
                            MessageBox.Show(
                                "Невозможно удалить товар, так как он присутствует в заказах клиентов!",
                                "Предупреждение",
                                MessageBoxButton.OK,
                                MessageBoxImage.Warning);
                            return;
                        }

                        var productToDelete = db.Product.Find(_currentProduct.Id);
                        if (productToDelete != null)
                        {
                            db.Product.Remove(productToDelete);
                            db.SaveChanges();
                        }
                    }

                    // Удаляем физический файл фото
                    if (!string.IsNullOrEmpty(_currentProduct.Photo) && File.Exists(_currentProduct.Photo))
                    {
                        try { File.Delete(_currentProduct.Photo); } catch { }
                    }

                    MessageBox.Show("Товар успешно удален!", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                    _mainWindow.RefreshProducts();
                    CloseWindow();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Ошибка при удалении:\n" + ex.Message, "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private void BtnBack_Click(object sender, RoutedEventArgs e)
        {
            CloseWindow();
        }

        private void CloseWindow()
        {
            _instance = null;
            _mainWindow.Show();
            this.Close();
        }

        protected override void OnClosed(EventArgs e)
        {
            _instance = null; // Сбрасываем при закрытии крестиком
            base.OnClosed(e);
        }
    }
}