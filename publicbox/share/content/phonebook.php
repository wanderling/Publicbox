<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Publicbox Phone Number Listing Page</title>
<link rel="stylesheet" href="/newuser/css/bootstrap.min.css" type="text/css">
<link rel="stylesheet" href="/content/css/page_style.css">
<script src="/content/js/jquery.min.js"></script>
<script src="/content/js/scripts.js"></script>
<link rel="stylesheet" href="/css/jquery-ui.min.css">
<script src="/content/js/jquery-ui.min.js"></script>
<meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=no, width=device-width">

<link rel="prefetch" type="application/l10n" href="locales/locales.ini" />
<script type="text/javascript" src="/content/js/l10n.js"></script>

</head>
<body>
<header id="header">
	<div class="container">
	   <a href="/">
		<div id="logo" scrolling="no"  >&nbsp;</div>
	   </a>
		<div id="menu-icon"></div>
		<nav id="top-nav">
			<ul>
				<li><a href="/content/" class="current" data-l10n-id="navbarHome">Home</a></li>
				<li><a href="/board/" data-l10n-id="navbarForum">Forum</a></li>
				<li><a href="/Shared/" data-l10n-id="navbarFiles">Files</a></li>
				<li><a href="/newuser/register.php">Phone Account Login</a></li>
				<li><a href="/content/#about" data-l10n-id="navbarAbout">About</a></li>
			</ul>
		</nav>
	</div>
</header>

<div class="container">
 <div id="extension-list">
	<div class="col-md-12">

		<div class="form-group">
			<font size="5">PublicBox Phone Listings.</font>
		</div>

		<div class="form-group">
			<font size="3">This is the complete listing of the users and numbers registered in this PublicBox Phone System. These numbers are only valid within this PublicBox, and do not reflect any real world telephone numbers or contacts.</font>
		</div>

		<div class="form-group">
			<hr />
		</div>

		<div class="form-group">
			<font size="4">Number&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Name</font>
		</div>

		<div class="form-group">
			<font size="4"><?php 
				// Create connection
				$conn = new mysqli('localhost','root','','asterisk');
				// Check connection
				if ($conn->connect_error) {
				    die("Connection failed: " . $conn->connect_error);
				} 
	
				$sql = "SELECT extension, name FROM users";
				$result = $conn->query($sql);

				if ($result->num_rows > 0) {
					// output data of each row
					while($row = $result->fetch_assoc()) {
				        	echo "" . $row["extension"]. "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" . $row["name"]. "<br>";
					}
				} else {
					echo "0 results";
				}
				$conn->close();
		 	?></font>
		</div>
	</div>
 </div>
</div>
</body>
</html>
<?php ob_end_flush(); ?>