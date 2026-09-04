<?php

// DATOS DE CONEXIÓN

$host     = getenv("DB_HOST");
$database = getenv("DB_NAME");
$user     = getenv("DB_USER");
$password = getenv("DB_PASSWORD");

// CONEXIÓN A MYSQL

$conexion = new mysqli(
    $host,
    $user,
    $password,
    $database
);

if ($conexion->connect_error) {
    die(
        "<h2>Error al conectar con la base de datos</h2>" .
        "<p>" .
        htmlspecialchars($conexion->connect_error) .
        "</p>"
    );
}

$conexion->set_charset("utf8mb4");

// CREAR TABLA SI NO EXISTE

$conexion->query("
    CREATE TABLE IF NOT EXISTS usuarios (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
");

$mensaje = "";

// AGREGAR O ELIMINAR USUARIO

if ($_SERVER["REQUEST_METHOD"] === "POST") {

    $accion = $_POST["accion"] ?? "";

    // AGREGAR

    if ($accion === "agregar") {

        $nombre = trim($_POST["nombre"] ?? "");

        if ($nombre !== "") {

            $stmt = $conexion->prepare(
                "INSERT INTO usuarios (nombre) VALUES (?)"
            );

            $stmt->bind_param("s", $nombre);
            $stmt->execute();
            $stmt->close();

            $mensaje = "Usuario guardado correctamente";
        }
    }

    // ELIMINAR

    if ($accion === "eliminar") {

        $id = intval($_POST["id"] ?? 0);

        if ($id > 0) {

            $stmt = $conexion->prepare(
                "DELETE FROM usuarios WHERE id = ?"
            );

            $stmt->bind_param("i", $id);
            $stmt->execute();
            $stmt->close();

            $mensaje = "Usuario eliminado correctamente";
        }
    }
}

// CONSULTAR USUARIOS

$resultado = $conexion->query(
    "SELECT id, nombre, fecha
     FROM usuarios
     ORDER BY id ASC"
);

?>

<!DOCTYPE html>

<html lang="es">

<head>

    <meta charset="UTF-8">

    <title>
        Terraform registered users
    </title>

    <style>

        body {
            font-family: Arial, sans-serif;
            max-width: 850px;
            margin: 40px auto;
            padding: 20px;
        }

        h1 {
            margin-bottom: 10px;
        }

        .conexion {
            color: green;
        }

        .mensaje {
            color: green;
            font-weight: bold;
        }

        .info {
            background: #f4f4f4;
            padding: 15px;
            margin-bottom: 25px;
            border-radius: 8px;
        }

        input[type="text"] {
            padding: 10px;
            width: 250px;
        }

        button {
            padding: 10px 20px;
            cursor: pointer;
        }

        .eliminar {
            color: #a00000;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 25px;
        }

        th,
        td {
            border: 1px solid #ccc;
            padding: 10px;
            text-align: left;
        }

        th {
            background-color: #eeeeee;
        }

    </style>

</head>

<body>

    <h1>
        Terraform Docker Lab
    </h1>

    <h2 class="conexion">
         Conexión exitosa a la base de datos
    </h2>

    <div class="info">

        <p>
            <strong>Base de datos:</strong>
            <?php echo htmlspecialchars($database); ?>
        </p>

        <p>
            <strong>Servidor MySQL:</strong>
            <?php echo htmlspecialchars($host); ?>
        </p>

        <p>
            <strong>Usuario MySQL:</strong>
            <?php echo htmlspecialchars($user); ?>
        </p>

    </div>

    <hr>

    <h2>
        Agregar usuario
    </h2>

    <?php if ($mensaje !== ""): ?>

        <p class="mensaje">
            ✅ <?php echo htmlspecialchars($mensaje); ?>
        </p>

    <?php endif; ?>

    <form method="POST">

        <input
            type="hidden"
            name="accion"
            value="agregar"
        >

        <input
            type="text"
            name="nombre"
            placeholder="Nombre del usuario"
            required
        >

        <button type="submit">
            Guardar
        </button>

    </form>

    <hr>

    <h2>
        Usuarios registrados
    </h2>

    <table>

        <thead>

            <tr>
                <th>#</th>
                <th>Nombre</th>
                <th>Fecha</th>
                <th>Acciones</th>
            </tr>

        </thead>

        <tbody>

            <?php $numero = 1; ?>

            <?php while ($fila = $resultado->fetch_assoc()): ?>

                <tr>

                    <td>
                        <?php echo $numero++; ?>
                    </td>

                    <td>
                        <?php echo htmlspecialchars($fila["nombre"]); ?>
                    </td>

                    <td>
                        <?php echo $fila["fecha"]; ?>
                    </td>

                    <td>

                        <form method="POST">

                            <input
                                type="hidden"
                                name="accion"
                                value="eliminar"
                            >

                            <input
                                type="hidden"
                                name="id"
                                value="<?php echo $fila["id"]; ?>"
                            >

                            <button
                                class="eliminar"
                                type="submit"
                            >
                                Eliminar
                            </button>

                        </form>

                    </td>

                </tr>

            <?php endwhile; ?>

        </tbody>

    </table>

</body>

</html>

<?php

$conexion->close();

?>