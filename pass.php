
<?php
// Set the password
$password = 'mypassword';

// Get the hash, letting the salt be automatically generated
$hash = crypt($password,'$6$aaasdger');


print $hash
?>

