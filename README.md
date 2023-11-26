
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

Для управления всеми ВМ была создана с помощью Terraform машина Bastion с доступом по порту 22 и с нее уже велась работы по развертыванию остальных машин. При поднятии Bastion также была создана соответствующая Security Gruop, а также нужная сеть и подсети.

Все использованные файлы находятся в этом же репозитории.

<details>
Содержание файла main.tf для Bastuon

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
  token     = "y0..."
  cloud_id  = "b1..."
  folder_id = "b1..."
  zone      = "ru-central1-a"
}

# ----- Настройка сети -----
resource "yandex_vpc_network" "my-network" {
  name = "my-network"
}

# ----- Настройка подсетей -----
resource "yandex_vpc_subnet" "subnet-a" {
  name = "subnet-a"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.my-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-b" {
  name = "subnet-b"
  zone = "ru-central1-b"
  network_id = yandex_vpc_network.my-network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

# ----- Группы безопасности -----

#Bastion
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion"
  description = "Public Group Zabbix"
  network_id  = yandex_vpc_network.my-network.id

  ingress {
    protocol       = "TCP"
    description    = "Connect to Bastion"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Out connect"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----- Создание ВМ Bastion -----
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
```

Содержание файла meta.yml
```
#cloud-config
users:
- name: chistov
  groups: sudo
  shell: /bin/bash
  sudo: ['ALL=(ALL) NOPASSWD:ALL']
  ssh-authorized-keys:
    - ssh-rsa AAAA...
```
   
</details>

После чего произведено подключение к Bastion `ssh 158.160.119.145` и были установлены Ansible, Terraform и коносль Яндекса `yc`. Заранее подготовленные файлы playbook и terraform были скопированы через SSH: `scp /home/chistov/diplom/* chistov@158.160.119.145:/home/chistov/diplom/`.

Так как сеть и подсети были уже созданы, в файле main.tf достаточно только указать ID подсетей. ID можно узнать командой `yc vpc subnet list`.

После внесения ID сетей в файл main.tf запускаю `terraform apply`. Все машины поднялись, сервера nginx и elastic сделаны без внешнего IP, пингуются по внутренним IP с машины Bastion и с нее же управляются.

![image](https://github.com/Ivashka80/Diplom/assets/121082757/ff1cc1b7-64a6-4349-b8bf-ada88d988b80)

Содержимое файла main.tf

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
  token     = "y0_A...."
  cloud_id  = "b1g52....."
  folder_id = "b1gvjn...."
  zone      = "ru-central1-a"
}

# ----- Группы безопасности -----
#Nginx
resource "yandex_vpc_security_group" "nginx" {
  name        = "priv-nginx"
  description = "Private Group Nginx"
  network_id  = "enp7nf3q8839m8j71d8b"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["192.168.10.0/24"]
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
  network_id  = "enp7nf3q8839m8j71d8b"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["192.168.10.0/24"]
    port           = 9200
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["192.168.10.0/24"]
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
  network_id  = "enp7nf3q8839m8j71d8b"

  ingress {
    protocol       = "TCP"
    description    = "Connect to Zabbix-server"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    protocol       = "ICMP"
    description    = "allow ping"
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
  network_id  = "enp7nf3q8839m8j71d8b"

  ingress {
    protocol       = "TCP"
    description    = "Connect to Kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
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
  network_id  = "enp7nf3q8839m8j71d8b"

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

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Out connect"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----- Создание ВМ nginx -----
# 1
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
    subnet_id = "e9buit315eqgh68jtqfl"
    nat = false
    security_group_ids = [yandex_vpc_security_group.nginx.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

# 2
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
    subnet_id = "e2lmdre2q39vcu243bqu"
    nat = false
    security_group_ids = [yandex_vpc_security_group.nginx.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

# ----- Target Group -----
resource "yandex_alb_target_group" "target-group" {
  name           = "target-group"

  target {
    subnet_id    = "e9buit315eqgh68jtqfl"
    ip_address   = yandex_compute_instance.nginx-1.network_interface.0.ip_address
  }

  target {
    subnet_id    = "e2lmdre2q39vcu243bqu"
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
  network_id  = "enp7nf3q8839m8j71d8b"
  security_group_ids = [yandex_vpc_security_group.balance.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "e9buit315eqgh68jtqfl"
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
    subnet_id = "e9buit315eqgh68jtqfl"
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
    subnet_id = "e9buit315eqgh68jtqfl"
    nat = false
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
    subnet_id = "e9buit315eqgh68jtqfl"
    nat = true
        security_group_ids = [yandex_vpc_security_group.kibana.id]
  }
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

```
</details>




