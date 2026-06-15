using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Input;
using BookStore; // Пространство имен EDMX
using System.Data.Entity;
using BookstoreWPF; // Для метода Include

namespace BookStore
{
    public partial class MainWindow : Window
    {
        private User _currentUser;
        private ICollectionView _productsView;
        private List<Product> _allProducts;

        public MainWindow(User user)
        {
            InitializeComponent();
            _currentUser = user;

            // 1. Отображаем ФИО пользователя в шапке
            if (_currentUser.Id == 0) // Гость
            {
                TxtUserInfo.Text = "Гость";
            }
            else
            {
                // Формируем строку "Фамилия Имя Отчество (Роль)"
                TxtUserInfo.Text = $"{_currentUser.Surname} {_currentUser.Name} {_currentUser.Patronymic} ({_currentUser.Role.Name})".Trim();
            }

            // 2. Настраиваем видимость кнопок в зависимости от роли
            SetupRoleAccess();

            // 3. Загружаем товары из БД
            LoadProducts();
        }

        private void SetupRoleAccess()
        {
            string role = _currentUser.Role.Name;
            bool isManager = role == "Менеджер";
            bool isAdmin = role == "Администратор";
            bool hasTools = isManager || isAdmin;

            // Панель инструментов (поиск, сортировка) видна только Менеджеру и Админу
            PanelTools.Visibility = hasTools ? Visibility.Visible : Visibility.Collapsed;
            BtnOrders.Visibility = hasTools ? Visibility.Visible : Visibility.Collapsed;
            // Кнопка добавления товара видна ТОЛЬКО Админу
            BtnAddProduct.Visibility = isAdmin ? Visibility.Visible : Visibility.Collapsed;
        }

        private void LoadProducts()
        {
            try
            {
                using (var db = new db_bookstoreEntities())
                {
                    // Явно подгружаем связанные таблицы, чтобы они не были null
                    _allProducts = db.Product
                        .Include("Category")
                        .Include("Producer")
                        .Include("Provider")
                        .Include("Unit") // На будущее, пригодится при редактировании
                        .ToList();
                }

                _productsView = CollectionViewSource.GetDefaultView(_allProducts);
                _productsView.Filter = ProductFilter;
                LstProducts.ItemsSource = _productsView;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка загрузки товаров из БД:\n" + ex.Message, "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        // Метод фильтрации, вызывается автоматически при обновлении View
        private bool ProductFilter(object obj)
        {
            if (obj is Product p)
            {
                // 1. Фильтрация по диапазону скидки
                var selectedFilter = (CmbFilter.SelectedItem as ComboBoxItem)?.Content.ToString();
                if (selectedFilter != null && selectedFilter != "Все диапазоны")
                {
                    decimal discount = p.Discount ?? 0;
                    if (selectedFilter == "0 - 12,99%" && (discount < 0 || discount >= 13)) return false;
                    if (selectedFilter == "13 - 16,99%" && (discount < 13 || discount >= 17)) return false;
                    if (selectedFilter == "17% и более" && discount < 17) return false;
                }

                // 2. Поиск по всем текстовым полям
                string searchText = TxtSearch.Text.ToLower().Trim();
                if (!string.IsNullOrEmpty(searchText))
                {
                    bool matches =
                        (p.Name != null && p.Name.ToLower().Contains(searchText)) ||
                        (p.Description != null && p.Description.ToLower().Contains(searchText)) ||
                        (p.Article != null && p.Article.ToLower().Contains(searchText)) ||
                        (p.Category != null && p.Category.Name != null && p.Category.Name.ToLower().Contains(searchText)) ||
                        (p.Producer != null && p.Producer.Name != null && p.Producer.Name.ToLower().Contains(searchText)) ||
                        (p.Provider != null && p.Provider.Name != null && p.Provider.Name.ToLower().Contains(searchText));

                    if (!matches) return false;
                }
                return true;
            }
            return false;
        }

        // --- ОБРАБОТЧИКИ РЕАЛЬНОГО ВРЕМЕНИ ---

        private void TxtSearch_TextChanged(object sender, TextChangedEventArgs e)
        {
            _productsView?.Refresh(); // Обновляет список при каждом нажатии клавиши
        }

        private void CmbFilter_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            _productsView?.Refresh();
        }

        private void CmbSort_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_productsView == null) return;
            _productsView.SortDescriptions.Clear();

            var selectedSort = (CmbSort.SelectedItem as ComboBoxItem)?.Content.ToString();
            if (selectedSort == "Цена ↑") _productsView.SortDescriptions.Add(new SortDescription("Price", ListSortDirection.Ascending));
            else if (selectedSort == "Цена ↓") _productsView.SortDescriptions.Add(new SortDescription("Price", ListSortDirection.Descending));
            else if (selectedSort == "Остаток ↑") _productsView.SortDescriptions.Add(new SortDescription("AmountInStock", ListSortDirection.Ascending));
            else if (selectedSort == "Остаток ↓") _productsView.SortDescriptions.Add(new SortDescription("AmountInStock", ListSortDirection.Descending));
        }

        // --- ПЕРЕХОДЫ ---

        private void BtnLogout_Click(object sender, RoutedEventArgs e)
        {
            LoginWindow login = new LoginWindow();
            login.Show();
            this.Close();
        }
        public void RefreshProducts()
        {
            LoadProducts(); // Просто перезагружаем список из БД
        }

        private void BtnAddProduct_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                ProductEditWindow editWin = new ProductEditWindow(null, this);
                this.Hide();
                editWin.Show();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Информация", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }
        private void BtnOrders_Click(object sender, RoutedEventArgs e)
        {
            OrdersWindow ordersWin = new OrdersWindow(_currentUser, this);
            this.Hide();
            ordersWin.Show();
        }

        private void LstProducts_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            if (_currentUser.Role.Name == "Администратор" && LstProducts.SelectedItem is Product selectedProduct)
            {
                try
                {
                    ProductEditWindow editWin = new ProductEditWindow(selectedProduct, this);
                    this.Hide();
                    editWin.Show();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Информация", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
        }
    }
}