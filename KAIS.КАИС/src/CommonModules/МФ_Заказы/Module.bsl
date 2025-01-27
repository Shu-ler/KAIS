#Область ПрограммныйИнтерфейс

// Обновить список заказов.
// 
// Параметры:
//  Профиль - СправочникСсылка.МФ_ПрофилиKAIS - Профиль
// 
// Возвращаемое значение:
//  Структура - Обновить список заказов:
// * Ошибка - Строка - 
// * НеизвестныеПоставщики - Массив Из Произвольный - Поставщики 
Функция ОбновитьСписокЗаказов(Профиль) Экспорт

	РезультатОбновления = Новый Структура;

	HTTPСоединение = Неопределено;
	ОбновленоЗаписей = 0;
	ИмяМетода = "GET";
	Продолжать = Истина;
	Сообщение = Новый СообщениеПользователю;

	НеизвестныеПоставщики = Новый Массив;
	
	// Получение набора профилей
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("Ссылка", Профиль);

	Запрос.Текст = "ВЫБРАТЬ
				   |	МФ_ПрофилиKAIS.Ссылка КАК Ссылка,
				   |	МФ_ПрофилиKAIS.РесурсЗаказы КАК РесурсЗаказы,
				   |	МФ_ПрофилиKAIS.РежимЗаказовБезДетализации КАК РежимЗаказовБезДетализации
				   |ИЗ
				   |	Справочник.МФ_ПрофилиKAIS КАК МФ_ПрофилиKAIS
				   |ГДЕ
				   |	МФ_ПрофилиKAIS.ПометкаУдаления = ЛОЖЬ
				   |	И МФ_ПрофилиKAIS.Ссылка = &Ссылка";
	НаборПрофилей = Запрос.Выполнить().Выбрать();
	
	// Обработка профилей
	Пока НаборПрофилей.Следующий() Цикл

		Профиль = НаборПрофилей.Ссылка;
		ДанныеПрофиля = Справочники.МФ_ПрофилиKAIS.ДанныеПрофиля(Профиль);

		Заголовки = Заголовки(Профиль);

		ПродолжатьЦикл = УстановитьСоединениеССайтом(HTTPСоединение, Заголовки, Профиль);

		Страница = 0;

		Пока ПродолжатьЦикл Цикл

			АдресРесурса = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(ДанныеПрофиля.РесурсЗаказы,
																				   Формат(Страница, "ЧГ=0;"),
																				   ДанныеПрофиля.РежимЗаказовБезДетализации);
			АдресРесурса = АдресРесурса + "&filters=%7B%22date_period%22%3A%22INTERVAL+1+MONTH%22%7D";
			Страница = Страница + 1;
			
			// Создать HTTP-запроса.
			HTTPЗапрос = Новый HTTPЗапрос(АдресРесурса, Заголовки);
			
			// Получить ответ сервера в виде объекта HTTPОтвет.
			Результат = HTTPСоединение.ВызватьHTTPМетод(ИмяМетода, HTTPЗапрос);

			Если Результат.КодСостояния <> 200 Тогда

				Сообщение.Текст = Строка(Результат.КодСостояния);
				Сообщение.Сообщить();

				Сообщение.Текст = ОписаниеОшибки();
				Сообщение.Сообщить();

				РезультатОбновления.Вставить("Ошибка", ОписаниеОшибки());
				РезультатОбновления.Вставить("НеизвестныеПоставщики", НеизвестныеПоставщики);

				Возврат РезультатОбновления;

			КонецЕсли;

			Ответ = Результат.ПолучитьТелоКакСтроку(КодировкаТекста.UTF8);

			//@skip-check query-in-loop
			ПродолжатьЦикл = ОбработатьСтраницуЗаказов(Профиль,
													   Ответ,
													   ОбновленоЗаписей,
													   НеизвестныеПоставщики,
													   ДанныеПрофиля);

		КонецЦикла;

		Константы.МФ_КАИСОбновлено.Установить(ТекущаяДатаСеанса());

		Сообщение.Текст = "Обновлено записей о заказах клиентов - " + Строка(ОбновленоЗаписей);
		Сообщение.Сообщить();

	КонецЦикла;

	РезультатОбновления.Вставить("НеизвестныеПоставщики", НеизвестныеПоставщики);

	Возврат РезультатОбновления;

КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Формирует заголовки для HTTP - соединения
// 
// Параметры:
//  Профиль - СправочникСсылка.МФ_ПрофилиKAIS - Профиль
// 
// Возвращаемое значение:
//  Соответствие из Строка - Заголовки
Функция Заголовки(Профиль)

	Хост = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Профиль, "Адрес");
	Реферер = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку("http://%1/", Хост);

	Заголовки = Новый Соответствие;

	Заголовки.Вставить("Host", Хост);
	Заголовки.Вставить("Connection", "keep-alive");
	Заголовки.Вставить("Upgrade-Insecure-Requests", "1");
	Заголовки.Вставить("User-Agent",
					   "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36 Edg/96.0.1054.62");
	Заголовки.Вставить("Accept",
					   "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9");
	Заголовки.Вставить("Referer", Реферер);
	//	Заголовки.Вставить("Accept-Encoding", "gzip, deflate");
	Заголовки.Вставить("Accept-Language", "ru,en;q=0.9,en-GB;q=0.8,en-US;q=0.7");
	Заголовки.Вставить("Cookie",
					   "PHPSESSID=pe8m04cl41iotc59f795itv9hfgfjue8; auth=69dad64f39ab8925696e61891f197f29; _ym_isad=2; company_id=79; notice_seen=1640671260; shop_brand_size=24px");
	Заголовки.Вставить("Accept-Encoding", "identity");

	Возврат Заголовки

КонецФункции

// Устанавливает HTTP-соединение
//
// Параметры:
//  HTTPСоединение	 - 	 - 
//  Заголовки		 - 	 - 
// 
// Возвращаемое значение:
//  Булево - завершено без ошибок
//
Функция УстановитьСоединениеССайтом(HTTPСоединение, Заголовки, Профиль)

	Успешно = Истина;
	Сообщение = Новый СообщениеПользователю;

	Адрес = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Профиль, "Адрес");

	Попытка
		HTTPСоединение = Новый HTTPСоединение(Адрес);
		//		Сообщение.Текст = "Установлено соединение с сервером для профиля " + Профиль.Наименование;		
	Исключение
		Сообщение.Текст = "Не удалось соединиться с сервером: " + Адрес + Символы.ПС + ОписаниеОшибки();
		Успешно = Ложь;
	КонецПопытки;

//	Сообщение.Сообщить();

	Возврат Успешно;

КонецФункции

// Обработать страницу заказов.
// 
// Параметры:
//  Профиль - СправочникСсылка.МФ_ПрофилиKAIS - Профиль
//  СтраницаВHTML - Строка - Страница ВHTML
//  Счетчик - Число - Счетчик
//  СписокПоставщиков - Массив - Список поставщиков
//  ДанныеПрофиля - Структура - Данные профиля:
// * Логин - Строка - 
// * Пароль - Строка - 
// * Адрес - Строка - 
// * РежимЗаказовБезДетализации - Строка - 
// * РежимЗаказовСДетализацией - Строка - 
// * РесурсЗаказы - Строка - 
// * РесурсЗаказ - Строка - 
// * РесурсКлиент - Строка - 
// * ВидНоменклатуры - СправочникСсылка.ВидыНоменклатуры - 
// * Склад - СправочникСсылка.Склады - 
// * ДнейПросмотра - Число - 
// 
// Возвращаемое значение:
//  Булево - Обработать страницу заказов
Функция ОбработатьСтраницуЗаказов(Профиль, СтраницаВHTML, Счетчик, СписокПоставщиков, ДанныеПрофиля)

	Чтение = Новый ЧтениеHTML;
	Чтение.УстановитьСтроку(СтраницаВHTML);

	ОбъектыDOM = Новый ПостроительDOM;
	Дом = ОбъектыDOM.Прочитать(Чтение);

	СтрокиТаблицы = Дом.ПолучитьЭлементыПоИмени("tr");

	Если СтрокиТаблицы.Количество() < 1 Тогда
		Возврат Ложь;
	КонецЕсли;

	Для Каждого СтрокаТ Из СтрокиТаблицы Цикл

		НаВыгрузку = СодержимоеСтрокиСпискаЗаказов(СтрокаТ, ДанныеПрофиля);

		Если ТипЗнч(НаВыгрузку) = Тип("Структура") Тогда

			Если НаВыгрузку.СтатусЗаказа <> Перечисления.МФ_КАИССтатусыЗаказов.Выполнен
				 И НаВыгрузку.СтатусЗаказа <> Перечисления.МФ_КАИССтатусыЗаказов.Отказ Тогда

				НайденЗаказ = Документы.ЗаказКлиента.НайтиПоРеквизиту("НомерПоДаннымКлиента", НаВыгрузку.Номер);

				Если НайденЗаказ.Пустая() Тогда

					//////////////////////////////////////////////////////////////////////////////
					КонтрагентСсылка = Справочники.Контрагенты.НайтиПоРеквизиту("МФ_КодКАИС", НаВыгрузку.КлиентКод);
					
					Если КонтрагентСсылка.Пустая() Тогда

						ИндексКонца = СтрНайти(НаВыгрузку.КлиентСайта, "  ");
						Наименование = ?(ИндексКонца = 0, НаВыгрузку.КлиентСайта, Лев(НаВыгрузку.КлиентСайта, ИндексКонца));
						Наименование = СокрЛП(Наименование);

						ЮрФизЛицо = Перечисления.ЮрФизЛицо.ЮрЛицо;
						
						Если СтрНачинаетсяС(Наименование, "Индивидуальный предприниматель ") Тогда
							
							Наименование = СтрЗаменить(Наименование, "Индивидуальный предприниматель ", "");
							ЮрФизЛицо = Перечисления.ЮрФизЛицо.ИндивидуальныйПредприниматель;
							
						ИначеЕсли СтрНачинаетсяС(Наименование, "ИП ") Тогда 
							
							Наименование = СтрЗаменить(Наименование, "ИП ", "");
							ЮрФизЛицо = Перечисления.ЮрФизЛицо.ИндивидуальныйПредприниматель;
														
						КонецЕсли;
						
						ПартнерСсылка = Справочники.Партнеры.ПустаяСсылка();

						Партнер = Справочники.Партнеры.СоздатьЭлемент();
						Партнер.Заполнить(Неопределено);
						Партнер.Наименование = Наименование;
						Партнер.НаименованиеПолное = Наименование;
						Партнер.Клиент = Истина;

						Попытка
							
							Партнер.Записать();
							ПартнерСсылка = Партнер.Ссылка;
							
						Исключение
							
							ОбщегоНазначения.СообщитьПользователю(ОписаниеОшибки());
							
						КонецПопытки;						
						
						КонтрагентОбъект = Справочники.Контрагенты.СоздатьЭлемент();
						КонтрагентОбъект.Заполнить(Неопределено);
						КонтрагентОбъект.МФ_КодКАИС = НаВыгрузку.КлиентКод;
						КонтрагентОбъект.Наименование = Наименование;
						КонтрагентОбъект.ЮрФизЛицо = ЮрФизЛицо;
						КонтрагентОбъект.Партнер = ПартнерСсылка;
						
						Попытка
							
							КонтрагентОбъект.Записать();
							КонтрагентСсылка = КонтрагентОбъект.Ссылка;
							
						Исключение
							
							ОбщегоНазначения.СообщитьПользователю(ОписаниеОшибки());
							
						КонецПопытки;
						
					Иначе
						
						ПартнерСсылка = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(КонтрагентСсылка, "Партнер");
						
					КонецЕсли;
					//////////////////////////////////////////////////////////////////////////////
					
					ДанныеЗаказа = ДанныеНовогоЗаказа(ДанныеПрофиля);

					ДанныеЗаказа.Вставить("МФ_Идентификатор", НаВыгрузку.Идентификатор);
					ДанныеЗаказа.Вставить("МФ_Номер", НаВыгрузку.Номер);
					ДанныеЗаказа.Вставить("Дата", НаВыгрузку.Дата);
					ДанныеЗаказа.Вставить("НомерПоДаннымКлиента", НаВыгрузку.Номер);
					ДанныеЗаказа.Вставить("ДатаПоДаннымКлиента", НаВыгрузку.Дата);
					ДанныеЗаказа.Вставить("Контрагент", КонтрагентСсылка);
					ДанныеЗаказа.Вставить("Партнер", ПартнерСсылка);
					ДанныеЗаказа.Вставить("Комментарий", СтрШаблон("Код клиента - %1, идентификатор клиента - %2",
																   НаВыгрузку.КлиентКод,
																   НаВыгрузку.КлиентСайта));

					Счетчик = Счетчик + 1;
					ЗаказКлиента = Документы.ЗаказКлиента.СоздатьДокумент();
					ЗаказКлиента.Заполнить(ДанныеЗаказа);

					ЗаполнитьЗначенияСвойств(ЗаказКлиента, ДанныеЗаказа,, "Организация");

					ЗаказКлиента.Валюта = ЗначениеНастроекПовтИсп.ВалютаРегламентированногоУчетаОрганизации(ДанныеПрофиля.Организация);

					СтрокиЗаказовНаСайте(Профиль,
										 НаВыгрузку.Идентификатор,
										 НаВыгрузку.Номер,
										 Неопределено,
										 Неопределено,
										 ЗаказКлиента,
										 ДанныеПрофиля);

					Попытка
						ЗаказКлиента.Записать(РежимЗаписиДокумента.Запись);
					Исключение
						ОбщегоНазначения.СообщитьПользователю(ОписаниеОшибки());
					КонецПопытки;

				КонецЕсли;

			КонецЕсли;

		КонецЕсли;

	КонецЦикла;

	Возврат ТипЗнч(НаВыгрузку) = Тип("Структура");

КонецФункции

// Возвращает распарсенную строку списка заказов.
// 
// Параметры:
//  СтрокаТ - Строка - Строка списка заказов
//  ДанныеПрофиля - См. СправочникМенеджер.МФ_ПрофилиKAIS.ДанныеПрофиля
// 
// Возвращаемое значение:
//  Неопределено, Дата, Структура:
//	* Дата - Дата  
Функция СодержимоеСтрокиСпискаЗаказов(СтрокаТ, ДанныеПрофиля)

	Дата = Неопределено;

	Если СтрокаТ.ЕстьАтрибут("order_id") Тогда

		КолонкиТаблицы = СтрокаТ.ПолучитьЭлементыПоИмени("td");

		Если КолонкиТаблицы.Количество() > 0 Тогда

			// Колонка 3 - дата заказа
			Дата = XmlЗначение(Тип("Дата"), КолонкиТаблицы[2].ПолучитьАтрибут("data-value"));
			Если Дата >= ДанныеПрофиля.МинимальнаяДата Тогда

				НаВыгрузку = Новый Структура;
				НаВыгрузку.Вставить("Дата", Дата);
				НаВыгрузку.Вставить("Идентификатор", СтрокаТ.ПолучитьАтрибут("order_id"));

				Если СтрокаТ.ЕстьАтрибут("order_number") Тогда
					НаВыгрузку.Вставить("Номер", СтрокаТ.ПолучитьАтрибут("order_number"));
				КонецЕсли;

	
				// Колонка 2 - код клиента
				ЭлементыSpan = КолонкиТаблицы[1].ПолучитьЭлементыПоИмени("span");
				КлиентКод = СтрЗаменить(ЭлементыSpan[1].ТекстовоеСодержимое, "[", "");
				КлиентКод = СтрЗаменить(КлиентКод, "]", "");
				НаВыгрузку.Вставить("КлиентКод", КлиентКод);
	
				// Колонка 2 - наименование клиента
				КлиентСайта = ИзвлечьТекст(КолонкиТаблицы[1].ТекстовоеСодержимое);
				ИндексНачала = СтрНайти(КлиентСайта, "]") + 1;
				КлиентСайта = СокрЛП(Сред(КлиентСайта, ИндексНачала));

				НаВыгрузку.Вставить("КлиентСайта", КлиентСайта);

				// Колонка 4
				НаВыгрузку.Вставить("Количество", КолонкиТаблицы[3].ПолучитьАтрибут("data-value"));
	
				// Колонка 5
				НаВыгрузку.Вставить("Сумма", КолонкиТаблицы[4].ПолучитьАтрибут("data-value"));
	
				// Колонка 6
				НаВыгрузку.Вставить("ЦенаДоставки", КолонкиТаблицы[5].ПолучитьАтрибут("data-value"));
	
				// Колонка 7
				НаВыгрузку.Вставить("Итого", КолонкиТаблицы[6].ПолучитьАтрибут("data-value"));
	
				// Колонка 8
				НаВыгрузку.Вставить("Оплата", ИзвлечьТекст(КолонкиТаблицы[7].ТекстовоеСодержимое));
	
				// Колонка 9
				НаВыгрузку.Вставить("ТорговаяТочкаКод", КолонкиТаблицы[8].ТекстовоеСодержимое);
	
				// Колонка 10
				НаВыгрузку.Вставить("Доставка", КолонкиТаблицы[9].ТекстовоеСодержимое);
	
				// Колонка 12
				ТекстСтатуса = СокрЛП(СтрЗаменить(ИзвлечьТекст(КолонкиТаблицы[11].ТекстовоеСодержимое), " ", ""));
				ЗначениеСтатуса = Перечисления.МФ_КАИССтатусыЗаказов[ТекстСтатуса];
				НаВыгрузку.Вставить("СтатусЗаказа", ЗначениеСтатуса);

			Иначе

				НаВыгрузку = Дата;

			КонецЕсли;

		КонецЕсли;

	Иначе

		НаВыгрузку = Неопределено;

	КонецЕсли;

	Возврат НаВыгрузку;

КонецФункции

// Данные нового заказа.
// 
// Параметры:
//  ДанныеПрофиля - См. СправочникМенеджер.МФ_ПрофилиKAIS.ДанныеПрофиля
// 
// Возвращаемое значение:
//  Структура - Данные нового заказа:
// * Статус - ПеречислениеСсылка.СтатусыЗаказовКлиентов - 
// * Автор - СправочникСсылка.Пользователи, СправочникСсылка.ВнешниеПользователи - 
// * Приоритет - СправочникСсылка.Приоритеты, Неопределено - 
// * Склад - СправочникСсылка.Склады - 
Функция ДанныеНовогоЗаказа(ДанныеПрофиля)

	ДанныеЗаказа = Новый Структура;
	ДанныеЗаказа.Вставить("Статус", Перечисления.СтатусыЗаказовКлиентов.НеСогласован);
	ДанныеЗаказа.Вставить("Автор", Пользователи.АвторизованныйПользователь());
	ДанныеЗаказа.Вставить("Приоритет", ЗначениеНастроекПовтИсп.ПолучитьПриоритетПоУмолчанию());
	ДанныеЗаказа.Вставить("Склад", ДанныеПрофиля.Склад);
	ДанныеЗаказа.Вставить("ЦенаВключаетНДС", Истина);
	ДанныеЗаказа.Вставить("Организация", ДанныеПрофиля.Организация);

	Возврат ДанныеЗаказа

КонецФункции

Функция ИзвлечьТекст(Текст)

	ЧистыйТекст = СтрЗаменить(Текст, Символы.ПС, "");
	ЧистыйТекст = СокрЛП(ЧистыйТекст);

	Возврат ЧистыйТекст;

КонецФункции

// Строки заказов на сайте.
// 
// Параметры:
//  Профиль Профиль
//  Номер - Неопределено, Строка - Номер
//  Шифр - Неопределено, Строка - Шифр
//  СписокПоставщиков - Неопределено - Список поставщиков
//  ВыборкаПоставщиков - Неопределено - Выборка поставщиков
//  ЗаказКлиента - ДокументОбъект.ЗаказКлиента - Заказ клиента
Процедура СтрокиЗаказовНаСайте(Профиль, Номер, Шифр, СписокПоставщиков, ВыборкаПоставщиков, ЗаказКлиента, ДанныеПрофиля)

	Сообщение = Новый СообщениеПользователю;
	ИмяМетода = "GET";
	HTTPСоединение = Неопределено;
	Продолжать = Истина;
	ОбновленоЗаказов = 0;

	Сигнатура = "вход RUR:</td><td>";
	ДлинаСигнатуры = СтрДлина(Сигнатура);

//	Состояние("Читаем заказ " + Шифр);  
	
	// Установка соединения с сайтом
	Заголовки = Заголовки(Профиль);
	Продолжать = УстановитьСоединениеССайтом(HTTPСоединение, Заголовки, Профиль);

	Если Продолжать Тогда

		АдресРесурсаШаблон = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Профиль, "РесурсЗаказ");

		АдресРесурса = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(АдресРесурсаШаблон, Номер);
		
		// Создать HTTP-запроса.
		HTTPЗапрос = Новый HTTPЗапрос(АдресРесурса, Заголовки);
		
		// Получить ответ сервера в виде объекта HTTPОтвет.
		Результат = HTTPСоединение.ВызватьHTTPМетод(ИмяМетода, HTTPЗапрос);

		Если Результат.КодСостояния <> 200 Тогда

			Сообщение.Текст = Строка(Результат.КодСостояния) + " - ЗаполнитьПоставщиковСайта";
			Сообщение.Сообщить();

			Сообщение.Текст = ОписаниеОшибки();
			Сообщение.Сообщить();

			Возврат;

		КонецЕсли;

		Ответ = Результат.ПолучитьТелоКакСтроку(КодировкаТекста.UTF8);

		Чтение = Новый ЧтениеHTML;
		Чтение.УстановитьСтроку(Ответ);

		ОбъектыDOM = Новый ПостроительDOM;
		Дом = ОбъектыDOM.Прочитать(Чтение);

		СтрокиТаблицы = Дом.ПолучитьЭлементыПоИмени("tr");
		Нечто = Дом.ПолучитьЭлементыПоИмени("supplier_id");
		
//		НаборЗаписей = РегистрыСведений.КАИС_Товары.СоздатьНаборЗаписей();
//		НаборЗаписей.Отбор.Идентификатор.Установить(Шифр);
//		НаборЗаписей.Записать();

		СуммаДокумента = 0;

		Для Каждого Эл Из СтрокиТаблицы Цикл

			СтрокаОтказана = Ложь;

			Если СокрЛП(Эл.ИмяКласса) = "detail_tr" И Эл.ЕстьАтрибут("order_id") И Эл.ЕстьАтрибут("cart_id") Тогда

				НаЗагрузку = Новый Структура; 
				
				// Заполнение данными из атрибутов
				НаЗагрузку.Вставить("Идентификатор", Эл.ПолучитьАтрибут("order_id"));
				ВставитьАттрибутСПроверкой(Эл, НаЗагрузку, "ПоставщикКод", "supplier_id");
				ВставитьАттрибутСПроверкой(Эл, НаЗагрузку, "ПоставщикСайта", "supplier");
				ВставитьАттрибутСПроверкой(Эл, НаЗагрузку, "Количество", "cnt", Истина);
				ВставитьАттрибутСПроверкой(Эл, НаЗагрузку, "Цена", "price", Истина);
				
				// Заполнение данными из таблицы
				КолонкиТаблицы = Эл.ПолучитьЭлементыПоИмени("td"); 
				
				// Колонка 2 - код строки в заказе на сайте
				НаЗагрузку.Вставить("НомерПозиции", СокрЛП(КолонкиТаблицы[1].ТекстовоеСодержимое));
				
				// Колонка 3 - артикул и наименование товара
				Строки = РазбитьПострочно(КолонкиТаблицы[2].ТекстовоеСодержимое);
				Если Строки.Количество() = 2 Тогда
					НаЗагрузку.Вставить("Артикул", Строки[0]);
					НаЗагрузку.Вставить("НоменклатураСайта", Строки[1]);
				ИначеЕсли Строки.Количество() = 1 Тогда
					НаЗагрузку.Вставить("Артикул", Строки[0]);
				КонецЕсли;
				
				// Колонка 4 - срок поставки
				НаЗагрузку.Вставить("СрокПоставки", СокрЛП(КолонкиТаблицы[3].ТекстовоеСодержимое));
				
				// Колонка 5 - входящая цена
				Нечто = КолонкиТаблицы[4].ПолучитьАтрибут("data-content");
				Индекс = Найти(Нечто, Сигнатура);
				Подстрока = Сред(Нечто, Индекс + ДлинаСигнатуры);
				ДлинаЧисла = Найти(Подстрока, "<");
				ВходСтрока = Лев(Подстрока, ДлинаЧисла - 1);
				Попытка
					НаЗагрузку.Вставить("Вход", Число(ВходСтрока));
				Исключение
					Нечто = КолонкиТаблицы[4].ПолучитьАтрибут("data-value");
					НаЗагрузку.Вставить("Вход", Число(Нечто));
				КонецПопытки;
				
				// Колонка 6 - расшифровка поставщика
				Текст = КолонкиТаблицы[6].ДочерниеУзлы[1].Заголовок;
				НачальныйСимвол = Найти(Текст, "]") + 2;
				НаЗагрузку.Вставить("НаименованиеПоставщика", Сред(Текст, НачальныйСимвол));
				
				// Колонка 12 - отказ
				Текст = СокрЛП(КолонкиТаблицы[11].ТекстовоеСодержимое);
				Если Найти(Текст, "Отказ") <> 0 Тогда
					НаЗагрузку.Вставить("Отказ", Истина);
				КонецЕсли;

				Артикул = "";
				Каталог = "";
				ПолучтьКаталогИАртикул(НаЗагрузку.Артикул, Артикул, Каталог);

				ТоварСсылка = Справочники.Номенклатура.НайтиПоРеквизиту("Артикул", Артикул);

				Если ТоварСсылка.Пустая() Тогда

					ТоварОбъект = НоваяНоменклатура(ДанныеПрофиля);

					ТоварОбъект.Наименование = НаЗагрузку.НоменклатураСайта;
					ТоварОбъект.Артикул = Артикул;

					Производитель = НайтиСоздатьПроизводителя(Каталог);

					ТоварОбъект.Производитель = Производитель;

					Попытка
						ТоварОбъект.Записать();
						ТоварСсылка = ТоварОбъект.Ссылка;
					Исключение
						ОбщегоНазначения.СообщитьПользователю(ОписаниеОшибки());
						ТоварСсылка = Справочники.Номенклатура.ПустаяСсылка();
					КонецПопытки;

				КонецЕсли;

				СтрокаТЧТовары = ЗаказКлиента.Товары.Добавить();

				СтрокаТЧТовары.Номенклатура = ТоварСсылка;
				СтрокаТЧТовары.Количество = НаЗагрузку.Количество;
				СтрокаТЧТовары.КоличествоУпаковок = НаЗагрузку.Количество;
				СтрокаТЧТовары.Цена = НаЗагрузку.Цена;
				СтрокаТЧТовары.Сумма = НаЗагрузку.Цена * НаЗагрузку.Количество;
				СтрокаТЧТовары.СуммаСНДС = СтрокаТЧТовары.Сумма;
				СтрокаТЧТовары.СтавкаНДС = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(ТоварСсылка, "СтавкаНДС");
				СтрокаТЧТовары.СуммаНДС = СтрокаТЧТовары.Сумма / 120 * 20;
				СтрокаТЧТовары.Обособленно = Истина;
				СтрокаТЧТовары.ВариантОбеспечения = Перечисления.ВариантыОбеспечения.КОбеспечению;

				СуммаДокумента = СуммаДокумента + СтрокаТЧТовары.Сумма;

			КонецЕсли;

		КонецЦикла;

		ЗаказКлиента.СуммаДокумента = СуммаДокумента;

	КонецЕсли;

КонецПроцедуры

// Возвращает ссылку найденного по наименованию либо созданного производителя
// 
// Параметры:
//  Наименование - Строка - Наименование
// 
// Возвращаемое значение:
//  СправочникСсылка.Производители - Производитель с наименованием Наименование
Функция НайтиСоздатьПроизводителя(Наименование)

	ПроизводительСсылка = Справочники.Производители.НайтиПоНаименованию(Наименование);

	Если ПроизводительСсылка.Пустая() Тогда

		ПроизводительОбъект = Справочники.Производители.СоздатьЭлемент();
		ПроизводительОбъект.Заполнить(Неопределено);

		ПроизводительОбъект.Наименование = Наименование;

		Попытка
			ПроизводительОбъект.Записать();
			ПроизводительСсылка = ПроизводительОбъект.Ссылка;
		Исключение
			ОбщегоНазначения.СообщитьПользователю(НСтр("ru='Ошибка создания производителя (каталога) с нименованием:'")
												  + Наименование);
		КонецПопытки;

	КонецЕсли;

	Возврат ПроизводительСсылка

КонецФункции

Функция НоваяНоменклатура(ДанныеПрофиля)

	ТоварОбъект = Справочники.Номенклатура.СоздатьЭлемент();
	ТоварОбъект.Заполнить(Неопределено);

	ТоварОбъект.ТипНоменклатуры = Перечисления.ТипыНоменклатуры.Товар;
	ТоварОбъект.ВидНоменклатуры = ДанныеПрофиля.ВидНоменклатуры;

	Попытка
		Справочники.Номенклатура.ЗаполнитьРеквизитыПоВидуНоменклатуры(ТоварОбъект);
	Исключение
// TODO:
	КонецПопытки;
	
//	ТоварОбъект.ЕдиницаИзмерения = Справочники.УпаковкиЕдиницыИзмерения.НайтиПоКоду();
	Возврат ТоварОбъект

КонецФункции

Процедура ВставитьАттрибутСПроверкой(Источник, Получатель, Ключ, ИмяАттрибута, Число = Ложь)

	Если Источник.ЕстьАтрибут(ИмяАттрибута) Тогда

		Значение = Источник.ПолучитьАтрибут(ИмяАттрибута);

		Если Число Тогда
			Значение = Число(Значение);
		КонецЕсли;

		Получатель.Вставить(Ключ, Значение);

	КонецЕсли;

КонецПроцедуры

Функция РазбитьПострочно(Текст)

	Результат = Новый Массив;

	Пока СтрДлина(Текст) > 0 Цикл

		Текст = СокрЛП(Текст);

		Подстрока = СтрПолучитьСтроку(Текст, 1);
		Текст = СокрЛП(Сред(Текст, СтрДлина(Подстрока) + 1));

		Подстрока = СокрЛП(Подстрока);
		Если СтрДлина(Подстрока) > 0 Тогда
			Результат.Добавить(Подстрока);
		КонецЕсли;

	КонецЦикла;

	Возврат Результат;

КонецФункции

Процедура ПолучтьКаталогИАртикул(ИсходнаяСтрока, Артикул, Каталог)

	Перем КэшАртикула, Поз;

	КэшАртикула = СокрЛП(ИсходнаяСтрока);
	
	// Поиск последнего пробела     
	Поз = СтрДлина(КэшАртикула);
	Пока Сред(КэшАртикула, Поз, 1) <> " " И Поз > 0 Цикл
		Поз = Поз - 1;
	КонецЦикла;

	Артикул = Сред(КэшАртикула, Поз + 1);
	Каталог = Лев(КэшАртикула, Поз - 1);

	Артикул = СтрЗаменить(Артикул, "_", "");
	Артикул = СтрЗаменить(Артикул, ".", "");
	Артикул = СтрЗаменить(Артикул, "-", "");
	Артикул = ВРег(Артикул);

КонецПроцедуры

#КонецОбласти