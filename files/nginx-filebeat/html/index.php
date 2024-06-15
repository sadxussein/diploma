<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Host Info</title>
</head>
<body>
    <h1>Host Information</h1>
    <p><strong>Host Name:</strong> <?php echo gethostname(); ?></p>
    <p><strong>Host IP Address:</strong> <?php echo $_SERVER['SERVER_ADDR']; ?></p>
    <p><strong>Time of Access:</strong> <?php echo date("Y-m-d H:i:s"); ?></p>
</body>
</html>
