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

# -----Snapshot -----
resource "yandex_compute_snapshot_schedule" "mysnapshot" {
  name = "snapshot"

  schedule_policy {
    expression = "0 1 * * *"
  }

  snapshot_count = 7

  snapshot_spec {
      description = "Daily snapshot"
 }

  retention_period = "168h"

  disk_ids = ["epdd0j3k0mmk9fckou7f", 
             "fhmaaqqc0clhcrgnu0hd",
             "fhmcng7u9h4kt8m2mipe",
             "fhmdbhp2rg8ekjtnvlk3",
             "fhmme5dossmrrb243p59",
             "fhmslv58ia1p6onl8mr9"]
}
