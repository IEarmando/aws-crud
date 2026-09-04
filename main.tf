terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.5"
    }
  }
}

provider "docker" {}

resource "docker_network" "app_network" {
  name = "terraform-app-network"
}

resource "docker_volume" "mysql_data" {
  name = "terraform-mysql-data"
}

resource "docker_image" "mysql" {
  name = "mysql:8.0"
}

resource "docker_container" "mysql" {
  name  = "mysql-db"
  image = docker_image.mysql.image_id

  env = [
    "MYSQL_ROOT_PASSWORD=${var.db_root_password}",
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}"
  ]

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["mysql-db"]
  }

  volumes {
    volume_name    = docker_volume.mysql_data.name
    container_path = var.container_path
  }

  restart = "unless-stopped"
}

resource "docker_image" "php" {
  name         = var.image_name
  keep_locally = true
}

resource "docker_container" "php" {
  name  = var.container_name
  image = var.image_name
  ports {
    internal = 80
    external = var.external_port
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  env = [
    "DB_HOST=mysql-db",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}"
  ]

  depends_on = [
    docker_container.mysql
  ]
}

resource "docker_image" "phpmyadmin" {
  name = "phpmyadmin:latest"
}

resource "docker_container" "phpmyadmin" {
  name  = "terraform-phpmyadmin"
  image = docker_image.phpmyadmin.image_id

  ports {
    internal = 80
    external = var.phpmyadmin_port
  }

  env = [
    "PMA_HOST=mysql-db",
    "PMA_PORT=3306"
  ]

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [
    docker_container.mysql
  ]
}

output "services" {
  value = {
    web = {
      url          = "http://localhost:${var.external_port}"
      container    = docker_container.php.name
      container_id = docker_container.php.id
      image        = var.image_name
    }

    database = {
      container    = docker_container.mysql.name
      container_id = docker_container.mysql.id
      database     = var.db_name
      user         = var.db_user
    }

    phpmyadmin = {
      url          = "http://localhost:${var.phpmyadmin_port}"
      container    = docker_container.phpmyadmin.name
      container_id = docker_container.phpmyadmin.id
    }
  }
}