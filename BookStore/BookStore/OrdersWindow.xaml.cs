using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using BookStore;

namespace BookStore
{
    // DTO-класс для удобного отображения в DataGrid
    public class OrderView
    {
        public int Id { get; set; }
        public DateTime CreationDate { get; set; }
        public DateTime? DeliveryDate { get; set; }
        public string ClientName { get; set; }
        public string PickUpPointAddress { get; set; }
        public string ReceiptCode { get; set; }
        public string StatusName { get; set; }
        public int StatusId { get; set; }
    }

    public partial class OrdersWindow : Window
    {
        private User _currentUser;
        private MainWindow _mainWindow;
        private List<OrderView> _allOrders;

        public OrdersWindow(User user, MainWindow mainWindow)
        {
            InitializeComponent();
            _currentUser = user;
            _mainWindow = mainWindow;
            LoadOrders();
        }

        private void LoadOrders()
        {
            try
            {
                using (var db = new db_bookstoreEntities())
                {
                    // Загружаем заказы со связанными таблицами
                    var orders = db.Order
                        .Include("User")
                        .Include("PickUpPoint")
                        .Include("OrderStatus")
                        .ToList();

                    // Проецируем в удобный для отображения класс
                    _allOrders = orders.Select(o => new OrderView
                    {
                        Id = o.Id,
                        CreationDate = o.CreationDate,
                        DeliveryDate = o.DeliveryDate,
                        ClientName = $"{o.User.Surname} {o.User.Name} {o.User.Patronymic}".Trim(),
                        PickUpPointAddress = $"{o.PickUpPoint.City}, {o.PickUpPoint.Street}, д. {o.PickUpPoint.Building}",
                        ReceiptCode = o.ReceiptCode,
                        StatusName = o.OrderStatus.Name,
                        StatusId = o.StatusId
                    }).ToList();

                    DgOrders.ItemsSource = _allOrders;

                    // Заполняем ComboBox фильтра уникальными статусами из БД
                    var statuses = db.OrderStatus.ToList();
                    foreach (var status in statuses)
                    {
                        CmbStatusFilter.Items.Add(new ComboBoxItem { Content = status.Name, Tag = status.Id });
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка загрузки заказов:\n" + ex.Message, "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void CmbStatusFilter_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_allOrders == null) return;

            var selectedItem = CmbStatusFilter.SelectedItem as ComboBoxItem;
            string filterText = selectedItem?.Content?.ToString();

            if (filterText == "Все статусы")
            {
                DgOrders.ItemsSource = _allOrders;
            }
            else
            {
                DgOrders.ItemsSource = _allOrders.Where(o => o.StatusName == filterText).ToList();
            }
        }

        private void BtnBack_Click(object sender, RoutedEventArgs e)
        {
            _mainWindow.Show();
            this.Close();
        }
    }
}