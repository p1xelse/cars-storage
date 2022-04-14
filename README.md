# kv cars-storage tarantool
## Данные 
```
{
    "key": "string",
    "value": "[SOME JSON]"
}
```
## Клонируем репозиторий и переходим в него

`https://github.com/p1xelse/cars-storage.git && cd cars-storage`

## Запуск
### Деплой 
Настроенное приложение можно протестировать здесь:

http://185.20.224.148:8081/

### Docker
Чтобы протестировать это у себя на пк, без настроек, можно поднять докер контейнер.

Для этого нужно установить докер на вашу машину, так же потребуется make.

Собрать и поднять контейнер можно с помощью последовательности команд:

```bash
make docker_build
make docker_run
```

Контейнер собран и запущен, нужно настроить кластер.

1. Переходим по http://localhost:8081/
2. В router нажимаем 'configure' и стави галочку на `api`, сохраняем `Create replica set`
3. В s1-master нажимаем configure и стави галочку на `storage`, сохраняем `Create replica set`
4. Нажимаем `Bootstrap vshard`
5. Done, кластер настроен.

## Тест функционала
В случае, если вы собрали у себя через докер, то используйте URL -  http://localhost:8081/. Если используете задеплоенное - http://185.20.224.148:8081/.

В нашем случае все примеры будут на локальном приложении в докер контейнере.

```bash
make docker_build
make docker_run
```

### Добавить элемент
```
curl -X POST -v -H "Content-Type: application/json" -d '{"key":"1", "value": {"firm": "Mersedes", "model": "AMG"}}' http://localhost:8081/kv
```

В случае успеха:
```
{"info":"Successfully created"}  
```
Повторый запрос:
```
{"info":"car already exist"}
```

### Получить элемент
Получим элемент с ключем равным 1 из предыдущего пункта
```
curl -X GET -v http://localhost:8081/kv/1
```
Получим:
```
{"key":"1","value":{"firm":"Mersedes","model":"AMG"}}
```
Попробуем запросить несуществующий элемент
```
curl -X GET -v http://localhost:8081/kv/23
```

Получим:
```
{"info":"car not found"}
```

### Изменить элемент
```
curl -X PUT -v -H "Content-Type: application/json" -d '{"value": {"firm":"BMW", "model":"M5"}}' http://localhost:8081/kv/1
```

Получим:
```
{"firm":"BMW","model":"M5"}
```

Проверим:
```
curl -X GET -v http://localhost:8081/kv/1
       
...

{"key":"1","value":{"firm":"BMW","model":"M5"}}
```

Введем некорректное тело:
```
curl -X PUT -v -H "Content-Type: application/json" -d '{"value": 123}' http://localhost:8081/kv/1
```

Получим:
```
{"info":"Incorrect body in request"}
```

### Удалить элемент
```
curl -X DELETE -v http://localhost:8081/kv/1 
```

Получим:
```
{"info":"Deleted"}
```

```
curl -X GET -v http://localhost:8081/kv/1                                        

...

{"info":"car not found"}%  
```

Запись действительно удалена

Если удалить несуществующию запись:
```
curl -X DELETE -v http://localhost:8081/kv/1123  
```

Получим:

```
{"info":"car not found"}%  
```

## UNIT и интеграционные тесты

Так же можно запустить UNIT и интеграционные тесты, но для этого нужен образ, в котором приложение не запущено:

### Соберем и запустим
```
make docker_build_test 
make docker_run_test 
```

Загрузится терминал bash контейнера, останется только подготовить все для тестов и запустить:

```
tarantoolctl rocks install luatest
./deps.sh
.rocks/bin/luatest test/
```

### Результат
```
root@c7794ee0f401:/home/cars-storage# .rocks/bin/luatest test/
.....................
Ran 21 tests in 3.657 seconds, 21 succeeded, 0 failed

```