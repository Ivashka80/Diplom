
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

* Так я не смог понять, как назначить Груупы безопасности через Terraform, чтобы к машинам для управления можно подключаться через Bastion. Потому в файле `main.tf` я создал Группы безопасности со всеми разрешениями, а редактировал их уже после всех настроек через Консоль управления личного кабинета Яндекс. Облоко.
* Не удалось найти решения установки Zabbix-server через Ansible, т.к. там помимо Zabbix надо создавать базу данных и пользователя в ней. Потому я подключился к Zabbix-server через SSH и сделал всё вручную по инструкции со страницы Zabbix. С установкой и настройкой Zabbix-agent вопрос не появилось и установил через Ansible.
* Сам Zabbix-server тоже пока для меня не совсем понятен, потому для агентов я настроил метрики, которые мне показались правильными, исходя из задания.
* Резервное копирование также настроил через Консоль управления.

Теперь сам порядок выполнения работ для поднятия инфраструктуры.
-----
1. Все виртуальные машины (ВМ) поднимаю с помощью Terraform. Помимо ВМ файле main.tf заданы установки для сети, подсетей, группы безопасности, балансировщик и т.п.

----

Все ВМ поднялись, работает Балансировшщик, настроен Роутер и Целевая группа.

*Скришоты из Консоли управления Яндекс*

<details>

</details>

*Содержимое файла `meta.yml`*

<details>

```
#cloud-config
users:
- name: chistov
  groups: sudo
  shell: /bin/bash
  sudo: ['ALL=(ALL) NOPASSWD:ALL']
  ssh-authorized-keys:
    - ssh-rsa AAA...

```
 
</details>

*Содержимое файла `main.tf`*

<details>

```
# ----- Провайдер -----
 terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "y0_AgAAAAABHHbtAATuwQAAAADyebfD66YPI7gxRXWMBhVKLNynZKKp53Y"
  cloud_id  = "b1g524jj0p1d4ofp1l6s"
  folder_id = "b1gvjnnl70b79k428v6p"
  zone      = "ru-central1-a"
}

# ----- Настройка сети -----
resource "yandex_vpc_network" "diplom-net" {
  name = "dilpom-net"
}

# ----- Настройка подсетей -----
resource "yandex_vpc_subnet" "subnet-a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom-net.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

# ----- Группы безопасности -----

# Bastion
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion"
  description = "Public Group Bastion"
  network_id  = "yandex_vpc_network.diplom-net.id"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#Nginx
resource "yandex_vpc_security_group" "nginx" {
  name        = "priv-nginx"
  description = "Private Group Nginx"
  network_id  = "yandex_vpc_network.diplom-net.id"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#Elastic
resource "yandex_vpc_security_group" "elastic" {
  name        = "priv-elastic"
  description = "Private Group Elasticsearch"
  network_id  = "yandex_vpc_network.diplom-net.id"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#Zabbix-server
resource "yandex_vpc_security_group" "zabbix" {
  name        = "pub-zabbix"
  description = "Public Group Zabbix"
  network_id  = "yandex_vpc_network.diplom-net.id"

  ingress {
    protocol       = "ANY"
    description    = "Connect to Zabbix-server"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Out connect"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#Kibana
resource "yandex_vpc_security_group" "kibana" {
  name        = "pub-kibana"
  description = "Public Group Kibana"
  network_id  = "yandex_vpc_network.diplom-net.id"

  ingress {
    protocol       = "ANY"
    description    = "Connect to Kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Out connect"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#L7-balance
resource "yandex_vpc_security_group" "balance" {
  name        = "pub-balance"
  description = "Public Group L7-balance"
  network_id  = "yandex_vpc_network.diplom-net.id"

  ingress {
    protocol          = "TCP"
    description       = "Health check"
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "ANY"
    description    = "Connect to Balance"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Out connect"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----- Создание ВМ nginx -----

# Bastion
resource "yandex_compute_instance" "bastion" {
  name = "bastion"
  hostname = "bastion"
  zone = "ru-central1-a"

  resources{
    cores = 2
    core_fraction = 20
    memory = 2
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a.id
    nat = true
        security_group_ids = [yandex_vpc_security_group.bastion.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

# Nginx-1
resource "yandex_compute_instance" "nginx-1" {
  name = "nginx-1"
  hostname = "nginx-1"
  zone = "ru-central1-a"

  resources{
    cores = 2
    core_fraction = 5
    memory = 1
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id ="yandex_vpc_subnet.subnet-a.id"
    nat = true
    security_group_ids = [yandex_vpc_security_group.nginx.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

Nginx-2
resource "yandex_compute_instance" "nginx-2" {
  name = "nginx-2"
  hostname = "nginx-2"
  zone = "ru-central1-b"

  resources{
    cores = 2
    core_fraction = 5
    memory = 1
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = "yandex_vpc_subnet.subnet-b.id"
    nat = true
    security_group_ids = [yandex_vpc_security_group.nginx.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

# ----- Target Group -----
resource "yandex_alb_target_group" "target-group" {
  name = "target-group"

  target {
    subnet_id  = "yandex_vpc_subnet.subnet-a.id"
    ip_address = yandex_compute_instance.nginx-1.network_interface.0.ip_address
  }

  target {
    subnet_id    = "yandex_vpc_subnet.subnet-b.id"
    ip_address   = yandex_compute_instance.nginx-2.network_interface.0.ip_address
  }
}


# ----- Backend -----
resource "yandex_alb_backend_group" "backend-group" {
  name                     = "backend-group"

  http_backend {
    name                   = "backend"
    weight                 = 1
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.target-group.id]
    load_balancing_config {
      panic_threshold      = 90
    }
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

# ----- HTTP router -----
resource "yandex_alb_http_router" "http-router" {
  name          = "http-router"
  labels        = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "my-virtual-host" {
  name                    = "my-virtual-host"
  http_router_id          = yandex_alb_http_router.http-router.id
  route {
    name                  = "my-way"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.backend-group.id
        timeout           = "60s"
      }
    }
  }
}

# ----- L-7 Balance -----
resource "yandex_alb_load_balancer" "my-balancer" {
  name        = "my-balancer"
  network_id  = "yandex_vpc_network.diplom-net.id"
  security_group_ids = [yandex_vpc_security_group.balance.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "yandex_vpc_subnet.subnet-a.id"
    }
  }

  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http-router.id
      }
    }
  }
}

# ----- VM Zabbix -----

resource "yandex_compute_instance" "zabbix" {
  name = "zabix"
  hostname = "zabbix-server"
  zone = "ru-central1-a"

  resources{
    cores = 2
    core_fraction = 20
    memory = 4
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = "yandex_vpc_subnet.subnet-a.id"
    nat = true
        security_group_ids = [yandex_vpc_security_group.zabbix.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

# ----- VM Elastic -----

resource "yandex_compute_instance" "elastic" {
  name = "elastic"
  hostname = "elastic"
  zone = "ru-central1-a"

  resources{
    cores = 2
    core_fraction = 20
    memory = 4
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = "yandex_vpc_subnet.subnet-a.id"
    nat = true
        security_group_ids = [yandex_vpc_security_group.elastic.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

# ----- Kibana -----
resource "yandex_compute_instance" "kibana" {
  name = "kibana"
  hostname = "kibana"
  zone = "ru-central1-a"

  resources{
    cores = 2
    core_fraction = 20
    memory = 6
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = "yandex_vpc_subnet.subnet-a.id"
    nat = true
        security_group_ids = [yandex_vpc_security_group.kibana.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

```
 
</details>

----

2. Начинаю работать с файлами `playbook`.

----

*Содержимое файла `ansible.cnf`*

<details>

   ```
[defaults]
inventory      = /home/chistov/diplom/hosts
forks          = 10
host_key_checking = False
remote_user = chistov
private_key_file = /home/chistov/.ssh/id_rsa
deprecation_warnings = False
   ```
</details>

*Содержимое файла `hosts` (адреса введены после поднятия машин). Все машины отвечают пингом через Ansible*

СКРИНШОТ АНСИБЛЕ, УДАЛИТЬ СТРОКУ

<details>
   
</details>


<details>

   ```
[bastion]
bastion ansible_host=158.160.99.198

[nginx]
nginx-1 ansible_host=158.160.100.82
nginx-2 ansible_host=158.160.82.234

[zabbixserver]
zabbixserver ansible_host=158.160.123.174

[elastic]
elasticsearch ansible_host=62.84.126.151

[kibana]
kibana ansible_host=158.160.108.67

[filebeat]
nginx-1 ansible_host=158.160.100.82
nginx-2 ansible_host=158.160.82.234

[all:vars]
ansible_ssh_user=chistov
ansible_ssh_private_key_file=/home/chistov/.ssh/id_rsa
   ```
</details>

- устанавливаю nginx на соответствующие ВМ

*Содержимое файла `playbook-nginx.yml`*

<details>

   ```
---
- name: Test connection
  hosts: nginx
  become: yes

  tasks:

  - name: Update apt
    apt:
      update_cache: yes

  - name: Install nginx
    apt: name=nginx state=latest

  - name: Change main page
    ansible.builtin.copy:
      src: /home/chistov/diplom/index.nginx-debian.html
      dest: /var/www/html/index.nginx-debian.html
      owner: chistov
      group: chistov
      mode: '0644'
   ```
</details>

*Работа Балансировщика по адресу `curl -v <публичный IP балансера>:80`. Так же сам сайт по адресу Балансировщика в браузере (адрес_сайта)*

СКРИШОТ ЗАПРОСА БАЛАНСИРОВЩИКА

<details>

</details>

На эти же ВМ следом ставлю Zabbix-agent и Filebeat с заменой файлов конфигурации.

*Содержимое файла `playbook-zabbix-agent.yml`*

<details>

   ```
---
- name: Install Zabbix-agent
  hosts: nginx
  become: yes

  tasks:
  - name: Get zabbix-agent
    ansible.builtin.get_url:
      url: https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu20.04_all.deb
      dest: /home/chistov/

  - name: Install repo zabbix-agent
    apt:
      deb: /home/chistov/zabbix-release_6.0-4+ubuntu20.04_all.deb

  - name: Update cash
    apt:
      update_cache: yes

  - name: install zabbix-agent
    apt:
      name: zabbix-agent
      state: latest

  - name: stop zabbix-agent
    service:
      name: zabbix-agent.service
      state: stopped

  - name: Copy conf-file
    copy:
      src: /home/chistov/diplom/zabbix_agentd.conf
      dest: /etc/zabbix/zabbix_agentd.conf
      mode: 0644
      owner: root
      group: root

  - name: Start zabbix-agent
    service:
      name: zabbix-agent.service
      state: started
   ```
</details>

*Содержимое файла `playbook-filebeat.yml`*

<details>

   ```
---
- name: Install Filebeat
  hosts: nginx
  become: yes

  tasks:
  - name: Get Filebeat
    ansible.builtin.get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/f/filebeat/filebeat-7.17.9-amd64.deb
      dest: /home/chistov/

  - name: Install Filebeat
    apt:
      deb: /home/chistov/filebeat-7.17.9-amd64.deb

  - name: Systemctl daemon reload
    systemd:
      daemon_reload: true
      name: filebeat.service
      state: started

  - name: Copy conf-file
    copy:
      src: /home/chistov/diplom/filebeat.yml
      dest: /etc/filebeat/filebeat.yml
      mode: 0644
      owner: root
      group: root

  - name: Restart Filebeat
    systemd:
      name: filebeat.service
      state: restarted
   ```
</details>

- Установка Zabbix-server по инструкции сайта Zabbix и последущая его настройка.

*Скришоты работы Zabbix*

<details>

   
</details>

- Установка Elasticsearch с заменой файла конфигурации

*Содержимое файла `elasticsearch.yml`*

<details>

   ```
---
- name: Install elastic
  hosts: elastic
  become: yes

  tasks:
  - name: Update apt
    apt:
      update_cache: yes

  - name: Install java
    apt: name=openjdk-11-jdk state=latest

  - name: Get elastic
    ansible.builtin.get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/e/elasticsearch/elasticsearch-7.17.9-amd64.deb
      dest: /home/chistov/

  - name: Install elastic
    apt:
      deb: /home/chistov/elasticsearch-7.17.9-amd64.deb

  - name: Systemctl daemon reload
    systemd:
      daemon_reload: true
      name: elasticsearch.service
      state: started

  - name: Copy conf-file
    copy:
      src: /home/chistov/diplom/elasticsearch.yml
      dest: /etc/elasticsearch/elasticsearch.yml
      mode: 0644
      owner: root
      group: elasticsearch

  - name: Restart elastic
    systemd:
      name: elasticsearch.service
      state: restarted
   ```
</details>

С помощью Ansible можно проверить работу Elasticserch, а также запросом `curl 'АДРЕС_БАЛАНСИРОВЩИКА:9200/_cluster/health?pretty`.

ЗДЕСЬ СКРИШОТ ЗАПРОСА.

<details>

</details>

- Установка Kibana

*Содержимое файла `playbook-kibana.yml` с заменой файла конфигурации*

<details>

   ```
---
- name: Install Kibana
  hosts: kibana
  become: yes

  tasks:
  - name: Get Kibana
    ansible.builtin.get_url:
      url: https://mirror.yandex.ru/mirrors/elastic/7/pool/main/k/kibana/kibana-7.17.9-amd64.deb
      dest: /home/chistov/

  - name: Install Kibana
    apt:
      deb: /home/chistov/kibana-7.17.9-amd64.deb

  - name: Systemctl daemon reload
    systemd:
      daemon_reload: true
      name: kibana.service
      state: started

  - name: Copy conf-file
    copy:
      src: /home/chistov/diplom/kibana.yml
      dest: /etc/kibana/kibana.yml
      mode: 0644
      owner: root
      group: kibana

  - name: Restart Kibana
    systemd:
      name: kibana.service
      state: restarted
   ```
</details>

Так как Filebeat ужк установлен на ВМ с nginx, начинаем получать уже информацию.

СКРИШОТЫ РАБОТЫ KIBANA

<details>

</details>

----

3. После всех ранее сделанных операций через Консоль управления в браузере меняю настройки Групп безопасности и чтобы ко всем ВМ можно было подключиться только через ВМ Bastion, к которой можно подключиться только по соединению SSH.

СКРИНШОТЫ ГРУПП БЕЗОПАСНОСТИ.

<details>

</details>

----

4. Настраиваю так же через Консоль резервное копирование.

СКРИНШОТЫ РЕЗЕРВНОГО КОПИРОВАНИЯ.

<details>

</details>

-----
На этом всё.
