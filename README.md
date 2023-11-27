
#  Дипломная работа по профессии «Системный администратор»

<details> 
   
Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Настройте все security groups на разрешение входящего ssh из этой security group. Эта вм будет реализовывать концепцию bastion host. Потом можно будет подключаться по ssh ко всем хостам через этот хост.

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)

</details>

# Решение

Все использованные при работе файлы находятся в этом же репозитории в директории `Files`.

К сожалению, у меня не хватило знаний и умений в некоторых пунктах:

* Так я не смог понять, как назначить Груупы безопасности, чтобы машины в приватной сети могли получать информацию из Интернета. В справке нашел  о NAT и шлюзе в Яндекс.Облаке, но так и не получилось с ним справиться. Потому в общем файле `main.tf` я создал Группы безопасности со всеми разрешениями, а редактировал их уже после всех настроек через Консоль управления личного кабинета Яндекс.Облако. 
* Не удалось понять способа установки Zabbix-server через Ansible, т.к. там помимо Zabbix надо создавать базу данных и пользователя в ней. Потому я подключился к Zabbix-server через SSH и сделал всё вручную по инструкции со страницы Zabbix. С установкой и настройкой Zabbix-agent вопрос не появилось и установил через Ansible.
* Сам Zabbix-server тоже пока для меня не совсем понятен, потому для агентов я настроил метрики, которые мне показались правильными, исходя из задания.
* Резервное копирование также настроил через Консоль управления.

Теперь сам порядок выполнения работ для поднятия инфраструктуры.
-----
1. Для начала я поднял только одну виртуальную машину (ВМ) Bastion. Все остальные операции я буду делать с Bastion. Вместе с Bastion также были созданы сеть и подсети, к которым потом позже подключатся остальные ВМ. Все файлы настройки созданы, будут скопированы по SSH и ключевые настройки редактироваться под нужные параметры.

----
2. Поднимаю оставшиеся ВМ. Ко всем есть подключение через Bastion. С ними же поднялись Балансировщик, оставшиеся Группы безопасности и Роутер.

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/025b9e85-7f1a-42df-94e0-2d823f9e087e)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/c963b398-2115-442a-b926-ba8cad0a0f61)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/74ed29bf-863e-41d1-9e33-ba833bc3462c)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/771e6a11-c6cd-4e41-b7f1-52603498cf6b)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/17a110a6-4412-4792-b146-abc3f858ee32)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/c90fdb05-bca7-4701-ba21-d3e4afc47ec8)

</details>

----
3. Установка nginx на соответствующие машины через ansible-playbook.

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/0b189170-fa79-41f2-aa04-7a931c967c67)

</details>

Делаю запрос к Балансировщику `curl -v <публичный IP балансера>:80`. Сайт также доступен по адресу Балансировщика http://158.160.132.191/.

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/5a34d0c5-0a83-4625-b143-3ac8c81c9e80)

</details>

----
4. Устанавливаю на эти же машины сразу Filebeat и Zabbix-agent.

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/14625dda-e291-46c4-8e19-3d0a91abb1b1)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/0c7cce52-5809-45a7-b0a1-d94fa998ec26)

</details>

----
5. Устанавливаю Zabbix-server. Как писал в начале, пришлось подключаться с Bastion через SSH и устанавливать по инструкции с сайта Zabbix, включая создание базы mysql. Zabbix-server доступен по внешнему адресу http://158.160.48.205/zabbix.

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/bbd97ca4-2497-4be9-9d0f-a94a7cbc539a)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/156f8758-e99c-469e-a1c6-7fc0a8ef7e01)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/4290758c-b63e-4a18-85b4-572696c35f86)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/602a5348-e805-40f9-bdd4-a59923e46242)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/bc6d6b59-a738-4694-885f-a8baf84f4ec0)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/a65fa419-ef57-4287-b836-5d2e440688b2)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/7d085dce-a335-4be6-b694-04143ce53d07)

</details>

----
6. Устанавливаю Elasticserch и проверяю запросом curl `localhost:9200/_cluster/health?pretty`.

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/43e03981-004d-422a-9486-ab1a70404fce)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/e5c7b29e-7b4b-4b13-b493-c25569831ed3)

</details>

----
7. Устанавливаю Kibana и проверяю http://158.160.118.169:5601/app/dev_tools#/console.

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/b6cac7d0-5069-4f7b-b5ab-1cfb921325a8)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/c3ac2e76-fdd5-41e2-b844-ab733bc45cf5)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/250e4d43-c4f5-4f86-9e1c-a55d26ae2df5)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/1fd1f959-e679-40b0-9940-63a4616d237e)

</details>

----

8. Создаю и поднимаю отдельно планировщик резервного копирования.

<details>
   
![image](https://github.com/Ivashka80/Diplom/assets/121082757/5e5a8d5a-6027-4383-8923-ff3264c97dd1)

</details>

----
9. Редактирую группы безопасности для некоторых ВМ.

*Bastion*

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/fc847980-39e9-4404-ad20-5fcba33d52cf)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/624328ed-326c-41e6-b0c9-fcd2eabd9247)

</details>

*Nginx*

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/b437831d-8cea-4e61-bd19-a9d503e3d6e9)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/1e3ae64f-b867-4d10-82f1-f8be6320b9c6)

</details>

*Балансировшик*

<details>
   
![image](https://github.com/Ivashka80/Diplom/assets/121082757/fb9c47a8-b1c0-462d-a703-11105eb45ba5)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/9f1398e6-6d47-426c-be16-c151b01afa48)

</details>

*Zabbix*

<details>
   
![image](https://github.com/Ivashka80/Diplom/assets/121082757/bb17631c-ad9d-40d0-a106-5060205ff90e)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/d20d25d5-b8ef-42ed-93cc-4a3299b4c9be)

</details>

*Elasticsearch*

<details>
   
![image](https://github.com/Ivashka80/Diplom/assets/121082757/d788e0a6-f58f-4128-8c3a-c9e9ef8174aa)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/407f5df6-a8c6-4f2a-8781-d19649e35b96)

</details>

*Kibana*

<details>

![image](https://github.com/Ivashka80/Diplom/assets/121082757/f6de97de-e047-418f-bb3f-a119b78204b3)

![image](https://github.com/Ivashka80/Diplom/assets/121082757/ab68fe8a-684f-4f58-9c82-1ab51ff61abe)

</details>

-----
На это всё.

