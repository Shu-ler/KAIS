//
//	Филимонов И.В.
//		+7 913 240 81 77
//		+7 905 084 20 06 (Telegram)
//		https://github.com/Shu-ler
//		

#Область ПрограммныйИнтерфейс

// см. ПодключаемыеКомандыПереопределяемый.ПриОпределенииВидовПодключаемыхКоманд 
Процедура ПриОпределенииВидовПодключаемыхКоманд(ВидыПодключаемыхКоманд) Экспорт
	
	Вид = ВидыПодключаемыхКоманд.Добавить();
	Вид.Имя = "ShopKAIS";
	Вид.ИмяПодменю = "ПодменюShopKAIS";
	Вид.Заголовок = НСтр("ru = 'Работа с ShopKAIS'");
	Вид.Картинка = БиблиотекаКартинок.ОтправитьЗаказТорговыеПредложения;
	Вид.Отображение = ОтображениеКнопки.Авто;
		
КонецПроцедуры

// см. ПодключаемыеКомандыПереопределяемый.ПриОпределенииКомандПодключенныхКОбъекту
Процедура ПриОпределенииКомандПодключенныхКОбъекту(НастройкиФормы, Источники, ПодключенныеОтчетыИОбработки, Команды) Экспорт

	Команда = Команды.Добавить();
	Команда.Вид = "ShopKAIS";
	Команда.Представление = НСтр("ru = 'Обновить заказы клиентов'");
	Команда.РежимЗаписи = "Записывать";
	Команда.ТипПараметра = Новый ОписаниеТипов("ДокументСсылка.ЗаказКлиента");
	Команда.ВидимостьВФормах = "ФормаСписка,ФормаСпискаДокументов";
	Команда.Обработчик = "МФ_ПодключаемыеКомандыКлиент.ОбновитьЗаказыКлиентов";

	Команда = Команды.Добавить();
	Команда.Вид = "ShopKAIS";
	Команда.Представление = НСтр("ru = 'Создать заказы поставщикам'");
	Команда.РежимЗаписи = "Записывать";
	Команда.ТипПараметра = Новый ОписаниеТипов("ДокументСсылка.ЗаказКлиента");
	Команда.ВидимостьВФормах = "ФормаСписка,ФормаСпискаДокументов";
	Команда.Обработчик = "МФ_ПодключаемыеКомандыКлиент.СоздатьЗаказыПоставщикам";

КонецПроцедуры

#КонецОбласти
