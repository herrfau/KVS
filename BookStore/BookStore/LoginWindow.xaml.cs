using BookStore;
using System.Linq;
using System.Windows;
using System.Data.Entity;

namespace BookstoreWPF
{
    public partial class LoginWindow : Window
    {
        public LoginWindow()
        {
            InitializeComponent();
        }

        private void BtnLogin_Click(object sender, RoutedEventArgs e)
        {
            string login = TxtLogin.Text;
            string password = PwdPassword.Password;

            try
            {
                // Обращаемся к БД через Entity Framework
                using (var db = new db_bookstoreEntities())
                {
                    // Ищем пользователя с таким логином и паролем
                    // .Include("Role") нужен, чтобы подгрузить название роли сразу
                    var user = db.User.Include("Role").FirstOrDefault(u => u.Login == login && u.Password == password);

                    if (user != null)
                    {
                        // Передаем найденного пользователя в Главное окно
                        MainWindow mainWindow = new MainWindow(user);
                        mainWindow.Show();
                        this.Close(); // Закрываем окно входа
                    }
                    else
                    {
                        MessageBox.Show("Неверный логин или пароль!", "Ошибка авторизации", MessageBoxButton.OK, MessageBoxImage.Error);
                    }
                }
            }
            catch (System.Exception ex)
            {
                MessageBox.Show("Ошибка подключения к базе данных:\n" + ex.Message, "Критическая ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void BtnGuest_Click(object sender, RoutedEventArgs e)
        {
            // Создаем объект-пустышку для гостя (в БД его нет, но интерфейс это поймет)
            var guest = new User
            {
                Id = 0,
                Surname = "",
                Name = "Гость",
                Patronymic = "",
                Login = "",
                Role = new Role { Name = "Гость" } // Создаем фейковую роль
            };

            MainWindow mainWindow = new MainWindow(guest);
            mainWindow.Show();
            this.Close();
        }
    }
}