<?php
header('Content-Type: application/json');
include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (!isset($_POST['name'], $_POST['username'], $_POST['email'], $_POST['password'], $_POST['department_id'], $_POST['semester'])) {
        echo json_encode(["success" => false, "message" => "Missing required fields"]);
        exit;
    }

    $name = trim($_POST['name']);
    $username = trim($_POST['username']);
    $email = trim($_POST['email']);
    $password = trim($_POST['password']);
    $department_id = trim($_POST['department_id']);
    $semester = trim($_POST['semester']);

    mysqli_begin_transaction($conn);

    try {
        $userQuery = "INSERT INTO users (username, password, role) VALUES (?, ?, 'student')";
        $stmt = mysqli_prepare($conn, $userQuery);
        mysqli_stmt_bind_param($stmt, "ss", $username, $password);
        mysqli_stmt_execute($stmt);

        $user_id = mysqli_insert_id($conn);

        $studentQuery = "INSERT INTO students (user_id, name, department_id, email, semester) VALUES (?, ?, ?, ?, ?)";
        $stmt2 = mysqli_prepare($conn, $studentQuery);
        mysqli_stmt_bind_param($stmt2, "issss", $user_id, $name, $department_id, $email, $semester);
        mysqli_stmt_execute($stmt2);

        mysqli_commit($conn);
        echo json_encode(["success" => true, "message" => "Student added successfully"]);
    } catch (Exception $e) {
        mysqli_rollback($conn);
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
    }
}
?>
