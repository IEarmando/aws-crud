<?php
$host     = getenv("DB_HOST");
$database = getenv("DB_NAME");
$user     = getenv("DB_USER");
$password = getenv("DB_PASSWORD");

$conexion = new mysqli($host, $user, $password, $database);

if ($conexion->connect_error) {
    die(
        "<h2>Error al conectar con la base de datos</h2>" .
        "<p>" . htmlspecialchars($conexion->connect_error) . "</p>"
    );
}

$conexion->set_charset("utf8mb4");

$conexion->query("
    CREATE TABLE IF NOT EXISTS usuarios (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
");