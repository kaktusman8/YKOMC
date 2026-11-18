# Карта исходников для преподавателя

Снимок описывает код рабочего checkout на 16 ноября 2026 года. Пути ниже указаны относительно исходного репозитория UCOMS; для запуска учебного приложения он не требуется. Это карта проверки происхождения правил, а не список зависимостей, которые студенты должны скопировать.

## Данные и математика

| Исходник | Что смотреть |
| --- | --- |
| `packages/configurator/data/fps_conditions.sqlite` | Канонический файл FPS |
| `packages/configurator/data/fps_conditions_model.json` | Исходная модель и происхождение данных |
| `packages/configurator/src/fps-conditions.ts:392` | Путь базы по умолчанию |
| `packages/configurator/src/fps-conditions.ts:500` | Декодирование stateId |
| `packages/configurator/src/fps-conditions.ts:547` | Адресация настроек и неоднозначные key |
| `packages/configurator/src/fps-conditions.ts:614` | Индекс 0 по умолчанию и mixed radix |
| `packages/configurator/src/fps-conditions.ts:730` | Открытие SQLite только для чтения |
| `packages/configurator/src/fps-conditions.ts:1044` | calculateFps |
| `packages/configurator/src/fps-conditions.ts:1084` | Множители и лимиты |
| `packages/configurator/src/fps-conditions.ts:1119` | Итоговый min и округление |
| `packages/configurator/src/fps-conditions.ts:1318` | Публичный source-native/legacy путь |
| `packages/configurator/src/fps-conditions.ts:2296` | Чтение настроек и опций |
| `packages/configurator/src/fps-conditions.ts:2355` | Получение GPU/CPU-факторов |
| `packages/configurator/src/fps-benchmark-calibration.ts:449` | Приоритет точной калибровки и native-профилей |
| `packages/configurator/src/fps-benchmark-calibration.ts:562` | Границы native GPU по якорям |
| `packages/configurator/src/fps-game-presets.ts:181` | Перевод качества в опции |
| `packages/configurator/src/fps-native-presets.ts:1065` | Выбор совместимого source-native профиля |
| `agents-context/contracts/fps-benchmark-calibration.md` | Контракт метрик, калибровок и происхождения |

## Интерфейс и HTTP

| Исходник | Что смотреть |
| --- | --- |
| `apps/api/src/configurator-routes.ts:1278` | Низкоуровневые FPS-маршруты |
| `apps/web/src/shared/api/configurator-fps.ts:61` | Типы ручного запроса и ответа |
| `apps/web/src/shared/api/configurator-fps.ts:244` | Отправка calculate |
| `apps/web/src/features/configurator/configurator-workload-library.tsx:161` | Черновик библиотеки и загрузка игр |
| `apps/web/src/features/configurator/configurator-workload-library.tsx:221` | Локальный поиск |
| `apps/web/src/features/configurator/configurator-workload-library.tsx:274` | Галочки и черновой список |
| `apps/web/src/features/configurator/configurator-workload-library.tsx:634` | Применение выбора |
| `apps/web/src/features/configurator/configurator-performance-panel.tsx:472` | Настройки панели и первые четыре игры |
| `apps/web/src/features/configurator/configurator-performance-panel.tsx:666` | Два расчёта High/Medium в сравнении |
| `apps/web/src/features/configurator/use-configurator-game-performance.ts:47` | Кеш, отмена, актуальность и ошибки |
| `apps/web/src/features/configurator/use-configurator-workload-analysis.ts:49` | Задержка 300 мс |

Наведение в библиотеке и FPS-панели не имеет вычислительных обработчиков: отклик задаётся оформлением. Открытие справочника, изменение черновика и подтверждение выбора — отдельные события. В учебном контракте эти события сохранены, а магазинные UUID комплектующих заменены прямым выбором CPU/GPU по slug.

## Что проверяет комплект

Числа в basic-reference получены из сырых факторных таблиц по явно описанной учебной формуле. Site-manual-reference получен вызовом существующего FpsConditionsStore.calculateFps над тем же файлом, открытым только для чтения. Этот эталон не заявляет равенства с workload-analysis и source-native сценариями.

`tools/check_data.py` проверяет копии данных и структуру SQLite. Запуск этого скрипта не доказывает, что студент уже реализовал правильный интерфейс или API: их нужно проверить по отдельным сценариям приёмки.
