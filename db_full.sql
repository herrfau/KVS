-- ChitaiGorodBookstore — полный скрипт развёртывания БД
-- Собран из: 00_create_database, 01_schema, 02_seed_data, 03_views

-- ================================================================
-- 00_create_database.sql
-- ================================================================
IF DB_ID(N'ChitaiGorodBookstore') IS NULL
BEGIN
    CREATE DATABASE [ChitaiGorodBookstore];
END
GO

ALTER DATABASE [ChitaiGorodBookstore] SET RECOVERY SIMPLE;
GO

-- ================================================================

-- 01_schema.sql

-- ================================================================
USE [ChitaiGorodBookstore];
GO

IF OBJECT_ID(N'dbo.OrderItem', N'U') IS NOT NULL DROP TABLE dbo.OrderItem;
IF OBJECT_ID(N'dbo.CustomerOrder', N'U') IS NOT NULL DROP TABLE dbo.CustomerOrder;
IF OBJECT_ID(N'dbo.BookStock', N'U') IS NOT NULL DROP TABLE dbo.BookStock;
IF OBJECT_ID(N'dbo.BookSupplier', N'U') IS NOT NULL DROP TABLE dbo.BookSupplier;
IF OBJECT_ID(N'dbo.BookAuthor', N'U') IS NOT NULL DROP TABLE dbo.BookAuthor;
IF OBJECT_ID(N'dbo.BonusCard', N'U') IS NOT NULL DROP TABLE dbo.BonusCard;
IF OBJECT_ID(N'dbo.Book', N'U') IS NOT NULL DROP TABLE dbo.Book;
IF OBJECT_ID(N'dbo.Customer', N'U') IS NOT NULL DROP TABLE dbo.Customer;
IF OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL DROP TABLE dbo.AppUser;
IF OBJECT_ID(N'dbo.Store', N'U') IS NOT NULL DROP TABLE dbo.Store;
IF OBJECT_ID(N'dbo.Author', N'U') IS NOT NULL DROP TABLE dbo.Author;
IF OBJECT_ID(N'dbo.Supplier', N'U') IS NOT NULL DROP TABLE dbo.Supplier;
IF OBJECT_ID(N'dbo.Publisher', N'U') IS NOT NULL DROP TABLE dbo.Publisher;
IF OBJECT_ID(N'dbo.Genre', N'U') IS NOT NULL DROP TABLE dbo.Genre;
IF OBJECT_ID(N'dbo.Role', N'U') IS NOT NULL DROP TABLE dbo.Role;
GO

CREATE TABLE dbo.Role (
    ID int IDENTITY(1,1) CONSTRAINT PK_Role PRIMARY KEY,
    Title nvarchar(50) NOT NULL CONSTRAINT UQ_Role_Title UNIQUE
);

CREATE TABLE dbo.AppUser (
    ID int IDENTITY(1,1) CONSTRAINT PK_AppUser PRIMARY KEY,
    RoleID int NOT NULL,
    FullName nvarchar(200) NOT NULL,
    Login nvarchar(120) NOT NULL CONSTRAINT UQ_AppUser_Login UNIQUE,
    Password nvarchar(120) NOT NULL,
    CONSTRAINT FK_AppUser_Role FOREIGN KEY (RoleID) REFERENCES dbo.Role(ID)
);

CREATE TABLE dbo.Genre (
    ID int IDENTITY(1,1) CONSTRAINT PK_Genre PRIMARY KEY,
    Title nvarchar(120) NOT NULL CONSTRAINT UQ_Genre_Title UNIQUE
);

CREATE TABLE dbo.Publisher (
    ID int IDENTITY(1,1) CONSTRAINT PK_Publisher PRIMARY KEY,
    Title nvarchar(160) NOT NULL CONSTRAINT UQ_Publisher_Title UNIQUE
);

CREATE TABLE dbo.Supplier (
    ID int IDENTITY(1,1) CONSTRAINT PK_Supplier PRIMARY KEY,
    Title nvarchar(160) NOT NULL CONSTRAINT UQ_Supplier_Title UNIQUE,
    Phone nvarchar(40) NULL
);

CREATE TABLE dbo.Author (
    ID int IDENTITY(1,1) CONSTRAINT PK_Author PRIMARY KEY,
    FullName nvarchar(160) NOT NULL CONSTRAINT UQ_Author_FullName UNIQUE
);

CREATE TABLE dbo.Book (
    ID int IDENTITY(1,1) CONSTRAINT PK_Book PRIMARY KEY,
    Article nvarchar(30) NOT NULL CONSTRAINT UQ_Book_Article UNIQUE,
    Title nvarchar(250) NOT NULL,
    Unit nvarchar(50) NOT NULL DEFAULT N'шт.',
    Price decimal(12,2) NOT NULL CONSTRAINT CK_Book_Price CHECK (Price >= 0),
    SupplierID int NOT NULL,
    PublisherID int NOT NULL,
    GenreID int NOT NULL,
    DiscountPercent decimal(5,2) NOT NULL DEFAULT 0 CONSTRAINT CK_Book_Discount CHECK (DiscountPercent BETWEEN 0 AND 100),
    StockQuantity int NOT NULL DEFAULT 0 CONSTRAINT CK_Book_Stock CHECK (StockQuantity >= 0),
    MinQuantity int NOT NULL DEFAULT 0 CONSTRAINT CK_Book_MinQuantity CHECK (MinQuantity >= 0),
    Description nvarchar(max) NULL,
    ImagePath nvarchar(260) NULL,
    YearPublished int NULL,
    IsOnlyOnOrder bit NOT NULL DEFAULT 0,
    CONSTRAINT FK_Book_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(ID),
    CONSTRAINT FK_Book_Publisher FOREIGN KEY (PublisherID) REFERENCES dbo.Publisher(ID),
    CONSTRAINT FK_Book_Genre FOREIGN KEY (GenreID) REFERENCES dbo.Genre(ID)
);

CREATE TABLE dbo.BookAuthor (
    BookID int NOT NULL,
    AuthorID int NOT NULL,
    CONSTRAINT PK_BookAuthor PRIMARY KEY (BookID, AuthorID),
    CONSTRAINT FK_BookAuthor_Book FOREIGN KEY (BookID) REFERENCES dbo.Book(ID) ON DELETE CASCADE,
    CONSTRAINT FK_BookAuthor_Author FOREIGN KEY (AuthorID) REFERENCES dbo.Author(ID)
);

CREATE TABLE dbo.BookSupplier (
    BookID int NOT NULL,
    SupplierID int NOT NULL,
    CONSTRAINT PK_BookSupplier PRIMARY KEY (BookID, SupplierID),
    CONSTRAINT FK_BookSupplier_Book FOREIGN KEY (BookID) REFERENCES dbo.Book(ID) ON DELETE CASCADE,
    CONSTRAINT FK_BookSupplier_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(ID)
);

CREATE TABLE dbo.Store (
    ID int IDENTITY(1,1) CONSTRAINT PK_Store PRIMARY KEY,
    Address nvarchar(300) NOT NULL CONSTRAINT UQ_Store_Address UNIQUE
);

CREATE TABLE dbo.BookStock (
    ID int IDENTITY(1,1) CONSTRAINT PK_BookStock PRIMARY KEY,
    BookID int NOT NULL,
    StoreID int NOT NULL,
    Quantity int NOT NULL CONSTRAINT CK_BookStock_Quantity CHECK (Quantity >= 0),
    CONSTRAINT UQ_BookStock UNIQUE (BookID, StoreID),
    CONSTRAINT FK_BookStock_Book FOREIGN KEY (BookID) REFERENCES dbo.Book(ID) ON DELETE CASCADE,
    CONSTRAINT FK_BookStock_Store FOREIGN KEY (StoreID) REFERENCES dbo.Store(ID)
);

CREATE TABLE dbo.Customer (
    ID int IDENTITY(1,1) CONSTRAINT PK_Customer PRIMARY KEY,
    FullName nvarchar(200) NOT NULL,
    Login nvarchar(120) NULL
);

CREATE TABLE dbo.BonusCard (
    ID int IDENTITY(1,1) CONSTRAINT PK_BonusCard PRIMARY KEY,
    CustomerID int NOT NULL CONSTRAINT UQ_BonusCard_Customer UNIQUE,
    CardNumber nvarchar(30) NOT NULL CONSTRAINT UQ_BonusCard_Number UNIQUE,
    BonusBalance decimal(12,2) NOT NULL DEFAULT 0 CONSTRAINT CK_BonusCard_Balance CHECK (BonusBalance >= 0),
    CONSTRAINT FK_BonusCard_Customer FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(ID) ON DELETE CASCADE
);

CREATE TABLE dbo.CustomerOrder (
    ID int IDENTITY(1,1) CONSTRAINT PK_CustomerOrder PRIMARY KEY,
    OrderNumber int NOT NULL CONSTRAINT UQ_CustomerOrder_Number UNIQUE,
    CustomerID int NULL,
    StoreID int NOT NULL,
    OrderDate date NOT NULL,
    DeliveryDate date NOT NULL,
    PickupCode int NOT NULL,
    Status nvarchar(80) NOT NULL,
    BonusSpent decimal(12,2) NOT NULL DEFAULT 0 CONSTRAINT CK_CustomerOrder_BonusSpent CHECK (BonusSpent >= 0),
    BonusEarned decimal(12,2) NOT NULL DEFAULT 0 CONSTRAINT CK_CustomerOrder_BonusEarned CHECK (BonusEarned >= 0),
    CONSTRAINT FK_CustomerOrder_Customer FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(ID),
    CONSTRAINT FK_CustomerOrder_Store FOREIGN KEY (StoreID) REFERENCES dbo.Store(ID)
);

CREATE TABLE dbo.OrderItem (
    ID int IDENTITY(1,1) CONSTRAINT PK_OrderItem PRIMARY KEY,
    OrderID int NOT NULL,
    BookID int NOT NULL,
    Quantity int NOT NULL CONSTRAINT CK_OrderItem_Quantity CHECK (Quantity > 0),
    Price decimal(12,2) NOT NULL CONSTRAINT CK_OrderItem_Price CHECK (Price >= 0),
    DiscountPercent decimal(5,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_OrderItem_Order FOREIGN KEY (OrderID) REFERENCES dbo.CustomerOrder(ID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItem_Book FOREIGN KEY (BookID) REFERENCES dbo.Book(ID)
);
GO

-- ================================================================

-- 02_seed_data.sql

-- ================================================================
USE [ChitaiGorodBookstore];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT dbo.Role (Title) VALUES (N'Admin'), (N'Manager'), (N'Client');
INSERT dbo.Genre (Title) VALUES (N'Учебник для вузов');
INSERT dbo.Genre (Title) VALUES (N'Учебное пособие');
INSERT dbo.Genre (Title) VALUES (N'Хрестоматия');
INSERT dbo.Genre (Title) VALUES (N'Художественная литература');
INSERT dbo.Publisher (Title) VALUES (N'Амрита-Русь');
INSERT dbo.Publisher (Title) VALUES (N'Аспект Пресс');
INSERT dbo.Publisher (Title) VALUES (N'ВКН');
INSERT dbo.Publisher (Title) VALUES (N'Время');
INSERT dbo.Publisher (Title) VALUES (N'Златоуст');
INSERT dbo.Publisher (Title) VALUES (N'Лениздат');
INSERT dbo.Publisher (Title) VALUES (N'Неолит');
INSERT dbo.Publisher (Title) VALUES (N'Прогресс книга');
INSERT dbo.Publisher (Title) VALUES (N'Т8 Издательские технологии');
INSERT dbo.Publisher (Title) VALUES (N'Яуза');
INSERT dbo.Supplier (Title, Phone) VALUES (N'Аркадий Гайдар', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Виктор Астафьев', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Гилберт Кит Честертон', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Дмитрий Мережковский', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Дмитрий Щербаков', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Дэниел Джей Барретт', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Екатерина Габарта, Ирина Игнатьева', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Иосиф Бродский', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Кирилл Каланджи', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Любовь Беликова, Инна Ерофеева, Татьяна Шутова', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Людмила Улицкая', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Роджер Осборн, Дэн Стерджис', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Сергей Моргачев', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Татьяна Лопаткина, Софья Маннапова', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Шон Кэрролл', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Юрий Родичев', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Яков Гордин', NULL);
INSERT dbo.Supplier (Title, Phone) VALUES (N'Янь Чуннянь Янь Чуннянь', NULL);
INSERT dbo.Author (FullName) VALUES (N'Аркадий Гайдар');
INSERT dbo.Author (FullName) VALUES (N'Виктор Астафьев');
INSERT dbo.Author (FullName) VALUES (N'Гилберт Кит Честертон');
INSERT dbo.Author (FullName) VALUES (N'Дмитрий Мережковский');
INSERT dbo.Author (FullName) VALUES (N'Дмитрий Щербаков');
INSERT dbo.Author (FullName) VALUES (N'Дэниел Джей Барретт');
INSERT dbo.Author (FullName) VALUES (N'Екатерина Габарта, Ирина Игнатьева');
INSERT dbo.Author (FullName) VALUES (N'Иосиф Бродский');
INSERT dbo.Author (FullName) VALUES (N'Кирилл Каланджи');
INSERT dbo.Author (FullName) VALUES (N'Любовь Беликова, Инна Ерофеева, Татьяна Шутова');
INSERT dbo.Author (FullName) VALUES (N'Людмила Улицкая');
INSERT dbo.Author (FullName) VALUES (N'Роджер Осборн, Дэн Стерджис');
INSERT dbo.Author (FullName) VALUES (N'Сергей Моргачев');
INSERT dbo.Author (FullName) VALUES (N'Татьяна Лопаткина, Софья Маннапова');
INSERT dbo.Author (FullName) VALUES (N'Шон Кэрролл');
INSERT dbo.Author (FullName) VALUES (N'Юрий Родичев');
INSERT dbo.Author (FullName) VALUES (N'Яков Гордин');
INSERT dbo.Author (FullName) VALUES (N'Янь Чуннянь Янь Чуннянь');
INSERT dbo.Store (Address) VALUES (N'125061, г. Лесной, ул. Подгорная, 8');
INSERT dbo.Store (Address) VALUES (N'630370, г. Лесной, ул. Шоссейная, 24');
INSERT dbo.Store (Address) VALUES (N'400562, г. Лесной, ул. Зеленая, 32');
INSERT dbo.Store (Address) VALUES (N'614510, г. Лесной, ул. Маяковского, 47');
INSERT dbo.Store (Address) VALUES (N'410542, г. Лесной, ул. Светлая, 46');
INSERT dbo.Store (Address) VALUES (N'620839, г. Лесной, ул. Цветочная, 8');
INSERT dbo.Store (Address) VALUES (N'443890, г. Лесной, ул. Коммунистическая, 1');
INSERT dbo.Store (Address) VALUES (N'603379, г. Лесной, ул. Спортивная, 46');
INSERT dbo.Store (Address) VALUES (N'603721, г. Лесной, ул. Гоголя, 41');
INSERT dbo.Store (Address) VALUES (N'410172, г. Лесной, ул. Северная, 13');
INSERT dbo.Store (Address) VALUES (N'614611, г. Лесной, ул. Молодежная, 50');
INSERT dbo.Store (Address) VALUES (N'454311, г.Лесной, ул. Новая, 19');
INSERT dbo.Store (Address) VALUES (N'660007, г.Лесной, ул. Октябрьская, 19');
INSERT dbo.Store (Address) VALUES (N'603036, г. Лесной, ул. Садовая, 4');
INSERT dbo.Store (Address) VALUES (N'394060, г.Лесной, ул. Фрунзе, 43');
INSERT dbo.Store (Address) VALUES (N'410661, г. Лесной, ул. Школьная, 50');
INSERT dbo.Store (Address) VALUES (N'625590, г. Лесной, ул. Коммунистическая, 20');
INSERT dbo.Store (Address) VALUES (N'625683, г. Лесной, ул. 8 Марта');
INSERT dbo.Store (Address) VALUES (N'450983, г.Лесной, ул. Комсомольская, 26');
INSERT dbo.Store (Address) VALUES (N'394782, г. Лесной, ул. Чехова, 3');
INSERT dbo.Store (Address) VALUES (N'603002, г. Лесной, ул. Дзержинского, 28');
INSERT dbo.Store (Address) VALUES (N'450558, г. Лесной, ул. Набережная, 30');
INSERT dbo.Store (Address) VALUES (N'344288, г. Лесной, ул. Чехова, 1');
INSERT dbo.Store (Address) VALUES (N'614164, г.Лесной,  ул. Степная, 30');
INSERT dbo.Store (Address) VALUES (N'394242, г. Лесной, ул. Коммунистическая, 43');
INSERT dbo.Store (Address) VALUES (N'660540, г. Лесной, ул. Солнечная, 25');
INSERT dbo.Store (Address) VALUES (N'125837, г. Лесной, ул. Шоссейная, 40');
INSERT dbo.Store (Address) VALUES (N'125703, г. Лесной, ул. Партизанская, 49');
INSERT dbo.Store (Address) VALUES (N'625283, г. Лесной, ул. Победы, 46');
INSERT dbo.Store (Address) VALUES (N'614753, г. Лесной, ул. Полевая, 35');
INSERT dbo.Store (Address) VALUES (N'426030, г. Лесной, ул. Маяковского, 44');
INSERT dbo.Store (Address) VALUES (N'450375, г. Лесной ул. Клубная, 44');
INSERT dbo.Store (Address) VALUES (N'625560, г. Лесной, ул. Некрасова, 12');
INSERT dbo.Store (Address) VALUES (N'630201, г. Лесной, ул. Комсомольская, 17');
INSERT dbo.Store (Address) VALUES (N'190949, г. Лесной, ул. Мичурина, 26');
INSERT dbo.Store (Address) VALUES (N'420151, г. Лесной, ул. Вишневая, 32');
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Никифорова Весения Николаевна', N'94d5ous@gmail.com', N'uzWC67' FROM dbo.Role WHERE Title = N'Admin';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Сазонов Руслан Германович', N'uth4iz@mail.com', N'2L6KZG' FROM dbo.Role WHERE Title = N'Admin';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Михайлюк Анна Вячеславовна', N'5d4zbu@tutanota.com', N'rwVDh9' FROM dbo.Role WHERE Title = N'Client';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Ситдикова Елена Анатольевна', N'ptec8ym@yahoo.com', N'LdNyos' FROM dbo.Role WHERE Title = N'Client';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Ворсин Петр Евгеньевич', N'1qz4kw@mail.com', N'gynQMT' FROM dbo.Role WHERE Title = N'Client';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Старикова Елена Павловна', N'4np6se@mail.com', N'AtnDjr' FROM dbo.Role WHERE Title = N'Client';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Одинцов Серафим Артёмович', N'yzls62@outlook.com', N'JlFRCZ' FROM dbo.Role WHERE Title = N'Admin';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Степанов Михаил Артёмович', N'1diph5e@tutanota.com', N'8ntwUp' FROM dbo.Role WHERE Title = N'Manager';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Ворсин Петр Евгеньевич', N'tjde7c@yahoo.com', N'YOyhfR' FROM dbo.Role WHERE Title = N'Manager';
INSERT dbo.AppUser (RoleID, FullName, Login, Password) SELECT ID, N'Старикова Елена Павловна', N'wpmrc3do@tutanota.com', N'RSbvHv' FROM dbo.Role WHERE Title = N'Manager';
INSERT dbo.Customer (FullName, Login) VALUES (N'Степанов Михаил Артёмович', N'');
INSERT dbo.BonusCard (CustomerID, CardNumber, BonusBalance) VALUES (SCOPE_IDENTITY(), N'BC00001', 25);
INSERT dbo.Customer (FullName, Login) VALUES (N'Никифорова Весения Николаевна', N'');
INSERT dbo.BonusCard (CustomerID, CardNumber, BonusBalance) VALUES (SCOPE_IDENTITY(), N'BC00002', 50);
INSERT dbo.Customer (FullName, Login) VALUES (N'Сазонов Руслан Германович', N'');
INSERT dbo.BonusCard (CustomerID, CardNumber, BonusBalance) VALUES (SCOPE_IDENTITY(), N'BC00003', 75);
INSERT dbo.Customer (FullName, Login) VALUES (N'Одинцов Серафим Артёмович', N'');
INSERT dbo.BonusCard (CustomerID, CardNumber, BonusBalance) VALUES (SCOPE_IDENTITY(), N'BC00004', 100);
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'А112Т4', N'Прокляты и убиты', N'шт.', 585, s.ID, p.ID, g.ID, 25, 6, 2, N'Роман-эпопею "Прокляты и убиты" Виктора Астафьева по праву считают одним из самых сильных и пронзительных произведений отечественной военной прозы.', N'resources/images/1.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Виктор Астафьев' AND p.Title = N'Яуза' AND g.Title = N'Художественная литература';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'А112Т4' AND a.FullName = N'Виктор Астафьев';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'А112Т4' AND s.Title = N'Виктор Астафьев';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 6 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'А112Т4' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'G843H5', N'Тайны и загадки отца БраунаТайны и загадки отца Брауна', N'шт.', 193, s.ID, p.ID, g.ID, 30, 9, 2, N'Гилберт Кит Честертон — признанный классик английской литературы, один из самых ярких писателей первой половины XX века. Классикой стали его романы и многочисленные эссе, однако любовь массового читателя принесли ему рассказы об отце Брауне, тихом, застенчивом священнике, мастерски раскрывающем наиболее запутанные загадки и преступления.', N'resources/images/2.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Гилберт Кит Честертон' AND p.Title = N'Яуза' AND g.Title = N'Художественная литература';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'G843H5' AND a.FullName = N'Гилберт Кит Честертон';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'G843H5' AND s.Title = N'Гилберт Кит Честертон';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 9 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'G843H5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'D325D4', N'Девайс', N'шт.', 1599, s.ID, p.ID, g.ID, 5, 12, 2, N'Молодой фрилансер Захар Скаро устраивается на очередную подработку. Задача, казалось бы, тривиальная: тестирование нового устройства. Вот только вопрос в том, тестированием какой реальности занимается этот новый Девайс?', N'resources/images/3.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Кирилл Каланджи' AND p.Title = N'Т8 Издательские технологии' AND g.Title = N'Художественная литература';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'D325D4' AND a.FullName = N'Кирилл Каланджи';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'D325D4' AND s.Title = N'Кирилл Каланджи';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 12 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'D325D4' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'S432T5', N'Необыкновенное обыкновенное чудо. Школьные истории', N'шт.', 549, s.ID, p.ID, g.ID, 15, 15, 2, N'', N'resources/images/4.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Людмила Улицкая' AND p.Title = N'Т8 Издательские технологии' AND g.Title = N'Художественная литература';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'S432T5' AND a.FullName = N'Людмила Улицкая';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'S432T5' AND s.Title = N'Людмила Улицкая';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 15 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'S432T5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'F325D4', N'Чук и Гек', N'шт.', 209, s.ID, p.ID, g.ID, 18, 3, 2, N'В книгу вошли повести и рассказы Аркадия Петровича Гайдара: "Чук и Гек", "Горячий камень" и "Сказка о военной тайне, о Мальчише-Кибальчише и его твердом слове"', N'resources/images/5.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Аркадий Гайдар' AND p.Title = N'Т8 Издательские технологии' AND g.Title = N'Художественная литература';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'F325D4' AND a.FullName = N'Аркадий Гайдар';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'F325D4' AND s.Title = N'Аркадий Гайдар';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 3 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'F325D4' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'G432G6', N'Информационная безопасность. Национальные стандарты Российской Федерации. 3-е издание. Учебное пособие', N'шт.', 3899, s.ID, p.ID, g.ID, 22, 3, 2, N'В учебном пособии рассмотрено более 300 действующих открытых документов национальной системы стандартизации Российской Федерации, включая международные и межгосударственные стандарты в области информационной безопасности по состоянию на начало 2023 года.', N'resources/images/6.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Юрий Родичев' AND p.Title = N'Прогресс книга' AND g.Title = N'Учебник для вузов';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'G432G6' AND a.FullName = N'Юрий Родичев';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'G432G6' AND s.Title = N'Юрий Родичев';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 3 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'G432G6' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'H542F5', N'Linux. Командная строка. Лучшие практики', N'шт.', 1799, s.ID, p.ID, g.ID, 4, 5, 2, N'Перейдите на новый уровень работы в Linux! Если вы системный администратор, разработчик программного обеспечения, SRE-инженер или пользователь Linux, книга поможет вам работать быстрее, элегантнее и эффективнее.', N'resources/images/7.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Дэниел Джей Барретт' AND p.Title = N'Прогресс книга' AND g.Title = N'Учебник для вузов';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'H542F5' AND a.FullName = N'Дэниел Джей Барретт';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'H542F5' AND s.Title = N'Дэниел Джей Барретт';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 5 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'H542F5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'C346F5', N'Квантовые миры и возникновение пространства-времени', N'шт.', 1349, s.ID, p.ID, g.ID, 5, 4, 2, N'Шон Кэрролл — физик-теоретик и один из самых известных в мире популяризаторов науки — заставляет нас по-новому взглянуть на физику. Столкновение с главной загадкой квантовой механики полностью поменяет наши представления о пространстве и времени.', N'resources/images/8.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Шон Кэрролл' AND p.Title = N'Прогресс книга' AND g.Title = N'Учебник для вузов';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'C346F5' AND a.FullName = N'Шон Кэрролл';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'C346F5' AND s.Title = N'Шон Кэрролл';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 4 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'C346F5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'F256G6', N'Вселенная. Происхождение жизни, смысл нашего существования и огромный космос', N'шт.', 1799, s.ID, p.ID, g.ID, 6, 2, 0, N'Знаменитый физик Шон Кэрролл в свойственной ему увлекательной манере объясняет принципы, которые лежат в основах научных революций от Дарвина до Эйнштейна, и показывает как невероятные научные открытия последнего столетия изменили наш мир.', N'resources/images/picture.png', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Шон Кэрролл' AND p.Title = N'Прогресс книга' AND g.Title = N'Учебник для вузов';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'F256G6' AND a.FullName = N'Шон Кэрролл';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'F256G6' AND s.Title = N'Шон Кэрролл';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 2 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'F256G6' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'J532V5', N'Пушкин. Бродский. Империя и судьба. В 2-х томах (комплект из 2-х книг)', N'шт.', 529, s.ID, p.ID, g.ID, 8, 6, 2, N'Первая книга двухтомника «Пушкин. Бродский. Империя и судьба» пронизана пушкинской темой. Пушкин — «певец империи и свободы» — присутствует даже там, где он впрямую не упоминается, ибо его судьба, как и судьба других героев книги, органично связана с трагедией великой империи.', N'resources/images/10.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Яков Гордин' AND p.Title = N'Время' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'J532V5' AND a.FullName = N'Яков Гордин';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'J532V5' AND s.Title = N'Яков Гордин';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 6 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'J532V5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'G643F4', N'Иосиф Бродский. Избранные эссе (комплект из 6-ти книг)', N'шт.', 4925, s.ID, p.ID, g.ID, 2, 24, 2, N'Шесть сборников избранных эссе Иосифа Бродского (1940-1996), великого поэта, драматурга, мыслителя, лауреата Нобелевской премии по литературе (1987): «Будущее или далекое прошлое», «Верь своей боли», «Как читать книгу», «О русской литературе», «О тирании», «Путеводитель по переименованному городу». Все тексты представлены на английском языке и в переводе на русский и открывают автора не только как поэта, но как историка, критика, и глубокого и ироничного мыслителя.', N'resources/images/11.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Иосиф Бродский' AND p.Title = N'Лениздат' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'G643F4' AND a.FullName = N'Иосиф Бродский';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'G643F4' AND s.Title = N'Иосиф Бродский';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 24 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'G643F4' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'J326V5', N'Тысячелетие императорской керамикиv', N'шт.', 2599, s.ID, p.ID, g.ID, 5, 4, 2, N'Фарфор стал величайшим символом китайской культуры. Это одно из выдающихся изобретений, внесших неоценимый вклад в мировую цивилизацию.', N'resources/images/12.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Янь Чуннянь Янь Чуннянь' AND p.Title = N'Лениздат' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'J326V5' AND a.FullName = N'Янь Чуннянь Янь Чуннянь';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'J326V5' AND s.Title = N'Янь Чуннянь Янь Чуннянь';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 4 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'J326V5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'J632F6', N'Вечные спутники: Портреты из всемирной литературы', N'шт.', 1599, s.ID, p.ID, g.ID, 0, 6, 2, N'Книга "Вечные спутники" - это цикл критических очерков о культуре и великих литераторах, сопровождавших жизнь и творчество русского писателя, поэта, литературного критика и общественного деятеля Дмитрия Мережковского (1865–1941).', N'resources/images/13.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Дмитрий Мережковский' AND p.Title = N'Лениздат' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'J632F6' AND a.FullName = N'Дмитрий Мережковский';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'J632F6' AND s.Title = N'Дмитрий Мережковский';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 6 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'J632F6' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'G632H6', N'Формирование литературной репутации Н.Г.Чернышевского в ХIX-XXI веках', N'шт.', 1349, s.ID, p.ID, g.ID, 2, 8, 2, N'Монография Д. А. Щербакова - новаторская. Поэтапно рассмотрены не только многочисленные суждения известных отечественных и зарубежных критиков, литературоведов, философов и политиков, различным образом характеризовавших Н. Г. Чернышевского в связи и вне связи со знаменитым романом "Что делать?', N'resources/images/14.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Дмитрий Щербаков' AND p.Title = N'Неолит' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'G632H6' AND a.FullName = N'Дмитрий Щербаков';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'G632H6' AND s.Title = N'Дмитрий Щербаков';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 8 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'G632H6' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'M642E5', N'Теория искусства. Краткий путеводитель', N'шт.', 879, s.ID, p.ID, g.ID, 3, 2, 0, N'', N'resources/images/15.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Роджер Осборн, Дэн Стерджис' AND p.Title = N'Неолит' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'M642E5' AND a.FullName = N'Роджер Осборн, Дэн Стерджис';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'M642E5' AND s.Title = N'Роджер Осборн, Дэн Стерджис';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 2 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'M642E5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'G543F5', N'Религиозные верования с древнейших времен до наших дней', N'шт.', 879, s.ID, p.ID, g.ID, 4, 6, 2, N'Настоящее издание представляет собой сборник переводов лекций по истории дохристианских и нехристианских религий, прочитанных в Лондоне в период с 1888 по 1891 гг. авторитетными исследователями данного раздела религиоведения.', N'resources/images/16.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Дмитрий Щербаков' AND p.Title = N'Амрита-Русь' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'G543F5' AND a.FullName = N'Дмитрий Щербаков';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'G543F5' AND s.Title = N'Дмитрий Щербаков';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 6 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'G543F5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'B653G6', N'Русский язык: Первые шаги. Часть 3. Учебное пособие', N'шт.', 2699, s.ID, p.ID, g.ID, 8, 9, 2, N'Пособие является завершающей частью учебного комплекса. Третья часть содержит 10 уроков (21-30, последний-повторительный). Усвоение лексико-грамматического материала рассчитано примерно на 200-240 часов аудиторных занятий.', N'resources/images/17.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Любовь Беликова, Инна Ерофеева, Татьяна Шутова' AND p.Title = N'Златоуст' AND g.Title = N'Учебное пособие';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'B653G6' AND a.FullName = N'Любовь Беликова, Инна Ерофеева, Татьяна Шутова';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'B653G6' AND s.Title = N'Любовь Беликова, Инна Ерофеева, Татьяна Шутова';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 9 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'B653G6' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'J735J7', N'Синтетический образ индивидуального психического мира', N'шт.', 1099, s.ID, p.ID, g.ID, 9, 4, 2, N'Психика подобна определенным объектам, это фиксируют сами люди в языке и искусстве. В данном исследовании рассматриваются в этом плане образы сосуда, воронки, дерева и крепости.', N'resources/images/18.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Сергей Моргачев' AND p.Title = N'Златоуст' AND g.Title = N'Хрестоматия';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'J735J7' AND a.FullName = N'Сергей Моргачев';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'J735J7' AND s.Title = N'Сергей Моргачев';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 4 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'J735J7' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'H436H7', N'Английский язык в спорте: Учебное пособие', N'шт.', 1999, s.ID, p.ID, g.ID, 2, 0, 0, N'Учебное пособие подготовлено для слушателей, изу чающих английский язык как язык специальности', N'resources/images/19.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Екатерина Габарта, Ирина Игнатьева' AND p.Title = N'Аспект Пресс' AND g.Title = N'Учебное пособие';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'H436H7' AND a.FullName = N'Екатерина Габарта, Ирина Игнатьева';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'H436H7' AND s.Title = N'Екатерина Габарта, Ирина Игнатьева';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 0 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'H436H7' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
INSERT dbo.Book (Article, Title, Unit, Price, SupplierID, PublisherID, GenreID, DiscountPercent, StockQuantity, MinQuantity, Description, ImagePath, YearPublished, IsOnlyOnOrder) SELECT N'H475R5', N'Лексика и грамматика современного китайского языка (к тому II учебника «Новый практический курс китайского языка» под редакцией Лю Сюня): учебное пособие', N'шт.', 608, s.ID, p.ID, g.ID, 25, 12, 2, N'Пособие выступает дополнением ко второму тому учебника «Новый практический курс китайского языка» (под редакцией Лю Сюня).', N'resources/images/20.jpg', 2024, 0 FROM dbo.Supplier s CROSS JOIN dbo.Publisher p CROSS JOIN dbo.Genre g WHERE s.Title = N'Татьяна Лопаткина, Софья Маннапова' AND p.Title = N'ВКН' AND g.Title = N'Учебное пособие';
INSERT dbo.BookAuthor (BookID, AuthorID) SELECT b.ID, a.ID FROM dbo.Book b CROSS JOIN dbo.Author a WHERE b.Article = N'H475R5' AND a.FullName = N'Татьяна Лопаткина, Софья Маннапова';
INSERT dbo.BookSupplier (BookID, SupplierID) SELECT b.ID, s.ID FROM dbo.Book b CROSS JOIN dbo.Supplier s WHERE b.Article = N'H475R5' AND s.Title = N'Татьяна Лопаткина, Софья Маннапова';
INSERT dbo.BookStock (BookID, StoreID, Quantity) SELECT b.ID, st.ID, 12 FROM dbo.Book b CROSS JOIN dbo.Store st WHERE b.Article = N'H475R5' AND st.Address = N'125061, г. Лесной, ул. Подгорная, 8';
DECLARE @CustomerID1 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Степанов Михаил Артёмович');
DECLARE @StoreID1 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'420151, г. Лесной, ул. Вишневая, 32');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (1, @CustomerID1, @StoreID1, '2024-02-27', '2024-04-20', 901, N'Завершен');
DECLARE @OrderID1 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID1, ID, 2, Price, DiscountPercent FROM dbo.Book WHERE Article = N'А112Т4';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID1, ID, 2, Price, DiscountPercent FROM dbo.Book WHERE Article = N'G843H5';
DECLARE @CustomerID2 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Никифорова Весения Николаевна');
DECLARE @StoreID2 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'410172, г. Лесной, ул. Северная, 13');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (2, @CustomerID2, @StoreID2, '2023-09-28', '2024-04-21', 902, N'Завершен');
DECLARE @OrderID2 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID2, ID, 1, Price, DiscountPercent FROM dbo.Book WHERE Article = N'G843H5';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID2, ID, 1, Price, DiscountPercent FROM dbo.Book WHERE Article = N'А112Т4';
DECLARE @CustomerID3 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Сазонов Руслан Германович');
DECLARE @StoreID3 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'125061, г. Лесной, ул. Подгорная, 8');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (3, @CustomerID3, @StoreID3, '2024-03-21', '2024-04-22', 903, N'Завершен');
DECLARE @OrderID3 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID3, ID, 10, Price, DiscountPercent FROM dbo.Book WHERE Article = N'D325D4';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID3, ID, 10, Price, DiscountPercent FROM dbo.Book WHERE Article = N'S432T5';
DECLARE @CustomerID4 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Одинцов Серафим Артёмович');
DECLARE @StoreID4 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'410172, г. Лесной, ул. Северная, 13');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (4, @CustomerID4, @StoreID4, '2024-02-20', '2024-04-23', 904, N'Завершен');
DECLARE @OrderID4 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID4, ID, 5, Price, DiscountPercent FROM dbo.Book WHERE Article = N'F325D4';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID4, ID, 4, Price, DiscountPercent FROM dbo.Book WHERE Article = N'D325D4';
DECLARE @CustomerID5 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Степанов Михаил Артёмович');
DECLARE @StoreID5 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'125061, г. Лесной, ул. Подгорная, 8');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (5, @CustomerID5, @StoreID5, '2024-03-17', '2024-04-24', 905, N'Завершен');
DECLARE @OrderID5 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID5, ID, 20, Price, DiscountPercent FROM dbo.Book WHERE Article = N'G432G6';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID5, ID, 20, Price, DiscountPercent FROM dbo.Book WHERE Article = N'H542F5';
DECLARE @CustomerID6 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Никифорова Весения Николаевна');
DECLARE @StoreID6 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'603036, г. Лесной, ул. Садовая, 4');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (6, @CustomerID6, @StoreID6, '2024-03-01', '2024-04-25', 906, N'Завершен');
DECLARE @OrderID6 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID6, ID, 2, Price, DiscountPercent FROM dbo.Book WHERE Article = N'А112Т4';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID6, ID, 2, Price, DiscountPercent FROM dbo.Book WHERE Article = N'G843H5';
DECLARE @CustomerID7 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Сазонов Руслан Германович');
DECLARE @StoreID7 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'630370, г. Лесной, ул. Шоссейная, 24');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (7, @CustomerID7, @StoreID7, '2024-02-29', '2024-04-26', 907, N'Завершен');
DECLARE @OrderID7 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID7, ID, 3, Price, DiscountPercent FROM dbo.Book WHERE Article = N'C346F5';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID7, ID, 3, Price, DiscountPercent FROM dbo.Book WHERE Article = N'F256G6';
DECLARE @CustomerID8 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Одинцов Серафим Артёмович');
DECLARE @StoreID8 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'625683, г. Лесной, ул. 8 Марта');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (8, @CustomerID8, @StoreID8, '2024-03-31', '2024-04-27', 908, N'Новый');
DECLARE @OrderID8 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID8, ID, 1, Price, DiscountPercent FROM dbo.Book WHERE Article = N'F325D4';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID8, ID, 1, Price, DiscountPercent FROM dbo.Book WHERE Article = N'G432G6';
DECLARE @CustomerID9 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Степанов Михаил Артёмович');
DECLARE @StoreID9 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'614510, г. Лесной, ул. Маяковского, 47');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (9, @CustomerID9, @StoreID9, '2024-04-02', '2024-04-28', 909, N'Новый');
DECLARE @OrderID9 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID9, ID, 5, Price, DiscountPercent FROM dbo.Book WHERE Article = N'J532V5';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID9, ID, 1, Price, DiscountPercent FROM dbo.Book WHERE Article = N'F256G6';
DECLARE @CustomerID10 int = (SELECT TOP 1 ID FROM dbo.Customer WHERE FullName = N'Степанов Михаил Артёмович');
DECLARE @StoreID10 int = (SELECT TOP 1 ID FROM dbo.Store WHERE Address = N'625683, г. Лесной, ул. 8 Марта');
INSERT dbo.CustomerOrder (OrderNumber, CustomerID, StoreID, OrderDate, DeliveryDate, PickupCode, Status) VALUES (10, @CustomerID10, @StoreID10, '2024-04-03', '2024-04-29', 910, N'Новый');
DECLARE @OrderID10 int = SCOPE_IDENTITY();
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID10, ID, 5, Price, DiscountPercent FROM dbo.Book WHERE Article = N'F256G6';
INSERT dbo.OrderItem (OrderID, BookID, Quantity, Price, DiscountPercent) SELECT @OrderID10, ID, 5, Price, DiscountPercent FROM dbo.Book WHERE Article = N'J532V5';
COMMIT TRANSACTION;
GO

-- ================================================================

-- 03_views.sql

-- ================================================================
USE [ChitaiGorodBookstore];
GO

CREATE OR ALTER VIEW dbo.vBookList
AS
SELECT
    b.ID,
    b.Article,
    b.Title,
    b.Unit,
    b.Price,
    b.DiscountPercent,
    CAST(ROUND(b.Price * (100 - b.DiscountPercent) / 100, 2) AS decimal(12,2)) AS FinalPrice,
    b.StockQuantity,
    b.MinQuantity,
    b.Description,
    b.ImagePath,
    b.YearPublished,
    b.IsOnlyOnOrder,
    g.ID AS GenreID,
    g.Title AS Genre,
    p.ID AS PublisherID,
    p.Title AS Publisher,
    s.ID AS SupplierID,
    s.Title AS Supplier,
    ISNULL(a.Authors, N'') AS Authors,
    CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.OrderItem oi WHERE oi.BookID = b.ID) THEN 1 ELSE 0 END AS bit) AS HasOrders,
    CASE
        WHEN b.StockQuantity = 0 THEN N'#d9d9d9'
        WHEN b.DiscountPercent > 25 THEN N'#23E1EF'
        WHEN b.StockQuantity < b.MinQuantity THEN N'#f19292'
        WHEN b.IsOnlyOnOrder = 1 THEN N'#fff3b0'
        ELSE N'#ffffff'
    END AS RowColor
FROM dbo.Book b
JOIN dbo.Genre g ON g.ID = b.GenreID
JOIN dbo.Publisher p ON p.ID = b.PublisherID
JOIN dbo.Supplier s ON s.ID = b.SupplierID
OUTER APPLY (
    SELECT STRING_AGG(au.FullName, N', ') AS Authors
    FROM dbo.BookAuthor ba
    JOIN dbo.Author au ON au.ID = ba.AuthorID
    WHERE ba.BookID = b.ID
) a;
GO

CREATE OR ALTER VIEW dbo.vOrderList
AS
SELECT
    o.ID,
    o.OrderNumber,
    o.CustomerID,
    c.FullName AS CustomerName,
    o.StoreID,
    st.Address AS StoreAddress,
    o.OrderDate,
    o.DeliveryDate,
    o.PickupCode,
    o.Status,
    o.BonusSpent,
    o.BonusEarned,
    SUM(oi.Quantity) AS BookCount,
    CAST(SUM(oi.Quantity * oi.Price * (100 - oi.DiscountPercent) / 100) - o.BonusSpent AS decimal(12,2)) AS TotalAmount,
    STRING_AGG(CONCAT(b.Article, N' ', b.Title, N' x', oi.Quantity), N'; ') AS ItemsText
FROM dbo.CustomerOrder o
LEFT JOIN dbo.Customer c ON c.ID = o.CustomerID
JOIN dbo.Store st ON st.ID = o.StoreID
LEFT JOIN dbo.OrderItem oi ON oi.OrderID = o.ID
LEFT JOIN dbo.Book b ON b.ID = oi.BookID
GROUP BY o.ID, o.OrderNumber, o.CustomerID, c.FullName, o.StoreID, st.Address, o.OrderDate, o.DeliveryDate,
         o.PickupCode, o.Status, o.BonusSpent, o.BonusEarned;
GO
