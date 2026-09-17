<?php
require_once __DIR__ . '/db.php';

$mensaje = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $accion = $_POST["accion"] ?? "";

    if ($accion === "agregar") {
        $nombre = trim($_POST["nombre"] ?? "");
        if ($nombre !== "") {
            $stmt = $conexion->prepare("INSERT INTO usuarios (nombre) VALUES (?)");
            $stmt->bind_param("s", $nombre);
            $stmt->execute();
            $stmt->close();
            $mensaje = "Usuario guardado correctamente";
        }
    }

    if ($accion === "eliminar") {
        $id = intval($_POST["id"] ?? 0);
        if ($id > 0) {
            $stmt = $conexion->prepare("DELETE FROM usuarios WHERE id = ?");
            $stmt->bind_param("i", $id);
            $stmt->execute();
            $stmt->close();
            $mensaje = "Usuario eliminado correctamente";
        }
    }
}

$resultado = $conexion->query("SELECT id, nombre, fecha FROM usuarios ORDER BY id ASC");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Terraform registered users</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

    <h1>Terraform Docker Lab</h1>

    <h2 class="conexion">Conexión exitosa a la base de datos</h2>

    <div class="info">
        <p><strong>Base de datos:</strong> <?php echo htmlspecialchars($database); ?></p>
        <p><strong>Servidor MySQL:</strong> <?php echo htmlspecialchars($host); ?></p>
        <p><strong>Usuario MySQL:</strong> <?php echo htmlspecialchars($user); ?></p>
    </div>

    <hr>

    <h2>Agregar usuario</h2>

    <?php if ($mensaje !== ""): ?>
        <p class="mensaje">✅ <?php echo htmlspecialchars($mensaje); ?></p>
    <?php endif; ?>

    <form method="POST">
        <input type="hidden" name="accion" value="agregar">
        <input type="text" name="nombre" placeholder="Nombre del usuario" required>
        <button type="submit">Guardar</button>
    </form>

    <hr>

    <h2>Usuarios registrados</h2>

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
                    <td><?php echo $numero++; ?></td>
                    <td><?php echo htmlspecialchars($fila["nombre"]); ?></td>
                    <td><?php echo htmlspecialchars($fila["fecha"]); ?></td>
                    <td>
                        <form method="POST">
                            <input type="hidden" name="accion" value="eliminar">
                            <input type="hidden" name="id" value="<?php echo $fila["id"]; ?>">
                            <button class="eliminar" type="submit">Eliminar</button>
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