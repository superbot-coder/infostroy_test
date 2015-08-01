unit a0ptConst;

interface

type
  TLogOperations = (
    lopEdit,
    lopDelete,
    lopExport,
    lopImport,
    lopBOChange,
    lopGrOpenAcc,
    lopGrCloseAcc,
    lopChangeOwner,
    lopAdminON,
    lopAdminOFF,
    lopCreateUser,
    lopDeleteUser,
    lopAddUsGroup,
    lopDelUsGroup,
    lopAddUsRole,
    lopDelUsRole,
    lopEditRole,
    lopClearLog,
    lopChangeLOp,
    lopBakUpAdm,
    lopRestoreAdm,
    lopAddSlGroup,
    lopDelSlGroup
  );

const
  strLogOperations : array [TLogOperations] of string = (
    ' 1 Редактирование сметных/системных данных',
    ' 2 Удаление сметных/системных данных',
    ' 3 Экспорт (выгрузка) сметных данных',
    ' 4 Импорт (загрузка) сметных данных',
    ' 5 Переключение бизнес-этапа для сметных данных',
    ' 6 Предоставление группе доступа к сметному объекту',
    ' 7 Запрет доступа к сметному объекту для группы',
    ' 8 Изменение собственника сметного объекта',
    ' 9 Включение разделения доступа',
    '10 Выключение разделения доступа',
    '11 Создание пользователя',
    '12 Удаление пользователя',
    '13 Привязка пользователя к группе',
    '14 Исключение пользователя из группы',
    '15 Назначение роли пользователю',
    '16 Снятие роли с пользователя',
    '17 Редактирование роли',
    '18 Очистка протокола (вручную)',
    '19 Изменение списка протоколируемых операций',
    '20 Выгрузка данных административного доступа',
    '21 Загрузка данных административного доступа',
    '22 Добавление подчиненной группы',
    '23 Удаление подчиненной группы'
  );

type
  TLogObjects = (
    lobProj,
    lobOS,
    lobLS,
    lobPS,
    lobAct,
    lobUser,
    lobRole,
    lobLog,
    lobAdm,
    lobRefer,
    lobGroup,
    lobSysObj,
    lobIndRef
  );

const
  strLogObjects: array [TLogObjects] of String = (
    ' 1 Проект',
    ' 2 ОС',
    ' 3 ЛС',
    ' 4 ПС (проектная смета)',
    ' 5 Акт',
    ' 6 Пользователь',
    ' 7 Роль',
    ' 8 Операции с протоколом',
    ' 9 Операции с разделением доступа',
    '10 Справочник',
    '11 Группа',
    '12 Системные объекты',
    '13 Справочники индексов'
  );

implementation

end.
