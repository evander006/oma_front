import 'package:oma/shared/models/installation_option.dart';
import 'package:oma/shared/models/product.dart';

const kProductImage = 'assets/images/img_icon.png';

const mockCategories = <String>[
  'Сантехника',
  'Инструменты',
  'Крепёж',
  'Электрика',
  'Отделка',
];

final mockProducts = <Product>[
  const Product(
    id: 'p1',
    name:
        'Смеситель кухонный с гибким изливом (графит+графит) Ledeme арт. L4399U-12',
    category: 'Сантехника',
    description:
        'Кухонный смеситель с гибким изливом. Демо-цена из исходной карточки.',
    specs: {
      'Артикул': 'L4399U-12',
      'Покрытие': 'Графит',
      'Излив': 'Гибкий',
      'Монтаж': 'Настольный',
    },
    priceByn: 182.75,
    imageAsset: 'assets/images/faucet.png',
    sku: 'L4399U-12',
    installHint: 'Платная услуга · Стоимость уточняется',
  ),
  const Product(
    id: 'p1b',
    name:
        'Смеситель кухонный с гибким изливом (чёрный) Ledeme арт. L4399U-12B',
    category: 'Сантехника',
    description: 'Чёрное исполнение смесителя из демо-каталога.',
    specs: {
      'Артикул': 'L4399U-12B',
      'Покрытие': 'Чёрный',
      'Излив': 'Гибкий',
    },
    priceByn: 210.73,
    imageAsset: 'assets/images/faucet_black.png',
    sku: 'L4399U-12B',
    installHint: 'Платная услуга · Стоимость уточняется',
  ),
  const Product(
    id: 'p2',
    name: 'Сифон для раковины',
    category: 'Сантехника',
    description: 'Сифон с переливом для умывальника. Комплект крепежа в коробке.',
    specs: {
      'Тип': 'Бутылочный',
      'Диаметр': '40 мм',
      'Материал': 'Пластик',
    },
    priceByn: 24.50,
    imageAsset: kProductImage,
    sku: 'OMA-SIP-002',
  ),
  const Product(
    id: 'p3',
    name: 'Ключ разводной 250 мм',
    category: 'Инструменты',
    description: 'Разводной ключ для сантехнических работ.',
    specs: {
      'Длина': '250 мм',
      'Челюсти': 'до 30 мм',
    },
    priceByn: 31.00,
    imageAsset: kProductImage,
    sku: 'OMA-TOOL-003',
  ),
  const Product(
    id: 'p4',
    name: 'Лента ФУМ 12 мм',
    category: 'Крепёж',
    description: 'Уплотнительная лента для резьбовых соединений.',
    specs: {
      'Ширина': '12 мм',
      'Длина': '10 м',
    },
    priceByn: 2.40,
    imageAsset: kProductImage,
    sku: 'OMA-FUM-004',
  ),
  const Product(
    id: 'p5',
    name: 'Шланг гибкий ½″ 0.5 м',
    category: 'Сантехника',
    description: 'Гибкая подводка для смесителя.',
    specs: {
      'Длина': '0.5 м',
      'Резьба': '½″',
    },
    priceByn: 8.90,
    imageAsset: kProductImage,
    sku: 'OMA-HOSE-005',
  ),
  const Product(
    id: 'p6',
    name: 'Кабель ВВГнг 3×1.5',
    category: 'Электрика',
    description: 'Кабель для внутренней проводки (демо-позиция).',
    specs: {
      'Сечение': '3×1.5',
      'Длина': '1 м',
    },
    priceByn: 3.20,
    imageAsset: kProductImage,
    sku: 'OMA-CAB-006',
  ),
  const Product(
    id: 'p7',
    name: 'Краска интерьерная белая 5 л',
    category: 'Отделка',
    description: 'Матовая краска для стен и потолков.',
    specs: {
      'Объём': '5 л',
      'Цвет': 'Белый',
    },
    priceByn: 45.00,
    imageAsset: kProductImage,
    sku: 'OMA-PNT-007',
  ),
  const Product(
    id: 'p8',
    name: 'Дюбель 6×40 (упак.)',
    category: 'Крепёж',
    description: 'Универсальные дюбели, 50 шт.',
    specs: {
      'Размер': '6×40',
      'Кол-во': '50 шт',
    },
    priceByn: 4.10,
    imageAsset: kProductImage,
    sku: 'OMA-DUB-008',
  ),
];

const mockInstallations = <InstallationOption>[
  InstallationOption(
    id: 'inst1',
    title: 'Установка смесителя',
    priceFromByn: 35,
    subtitle: 'Демонтаж старого + монтаж нового',
  ),
  InstallationOption(
    id: 'inst2',
    title: 'Замена сифона',
    priceFromByn: 20,
    subtitle: 'С проверкой герметичности',
  ),
  InstallationOption(
    id: 'inst3',
    title: 'Подключение гибкой подводки',
    priceFromByn: 15,
  ),
];
