using System;
using System.Globalization;
using System.IO;
using System.Windows.Data;
using System.Windows.Media.Imaging;

namespace BookStore.Converters
{
    public class ImagePathConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            string path = value as string;

            // 1. Если в БД пусто или null, сразу отдаем заглушку
            if (string.IsNullOrWhiteSpace(path))
                return GetFallbackImage();

            string fullPath = null;

            // 2. Пытаемся найти файл в разных местах
            if (Path.IsPathRooted(path))
            {
                // Если путь абсолютный (например, C:\Images\book.jpg)
                if (File.Exists(path)) fullPath = path;
            }
            else
            {
                // Если путь относительный (например, Images\book.jpg или просто book.jpg)
                string appDir = AppDomain.CurrentDomain.BaseDirectory; // Папка с запущенным .exe

                // Вариант А: Ищем просто в папке с приложением
                string pathA = Path.Combine(appDir, path);
                if (File.Exists(pathA)) fullPath = pathA;

                // Вариант Б: Если в БД лежит ТОЛЬКО имя файла (например, "book1.jpg"), ищем в папке Images
                if (fullPath == null && !path.Contains("\\"))
                {
                    string pathB = Path.Combine(appDir, "Images", path);
                    if (File.Exists(pathB)) fullPath = pathB;
                }

                // Вариант В: Ищем в папке проекта (полезно при отладке в Visual Studio)
                if (fullPath == null)
                {
                    try
                    {
                        string projectDir = Directory.GetParent(appDir).Parent.Parent.FullName;
                        string pathC = Path.Combine(projectDir, path);
                        if (File.Exists(pathC)) fullPath = pathC;
                    }
                    catch { }
                }
            }

            // 3. Если файл найден, загружаем его
            if (fullPath != null)
            {
                try
                {
                    return LoadImageSafely(fullPath);
                }
                catch { }
            }

            // 4. Если ничего не нашли, отдаем заглушку
            return GetFallbackImage();
        }

        /// <summary>
        /// Безопасная загрузка изображения (без блокировки файла на диске)
        /// </summary>
        private BitmapImage LoadImageSafely(string path)
        {
            BitmapImage img = new BitmapImage();
            img.BeginInit();
            img.CacheOption = BitmapCacheOption.OnLoad; // ВАЖНО: загружает в память и отпускает файл
            img.UriSource = new Uri(path, UriKind.Absolute);
            img.EndInit();
            img.Freeze(); // Делает изображение потокобезопасным
            return img;
        }

        private BitmapImage GetFallbackImage()
        {
            try
            {
                // Загружаем заглушку из ресурсов проекта
                return new BitmapImage(new Uri("pack://application:,,,/Resources/picture.png", UriKind.Absolute));
            }
            catch
            {
                return null;
            }
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    // Оставляем ProductBackgroundConverter как был
    public class ProductBackgroundConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length == 2 && values[0] is decimal stock && values[1] is decimal discount)
            {
                if (stock <= 0) return System.Windows.Media.Brushes.LightGray;
                if (discount > 25) return new System.Windows.Media.SolidColorBrush((System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString("#23E1EF"));
            }
            return System.Windows.Media.Brushes.White;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture) => throw new NotImplementedException();
    }
}