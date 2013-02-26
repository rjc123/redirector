#!/bin/sh

#
#  generate 410 page for a site
#
#  usage: tools/generate_410.sh "$site" "$host" "$redirection_date" "$tna_timestamp" "$title" "$furl" "$new_url"

set -e

site="$1"
host="$2"
redirection_date="$3"
tna_timestamp="$4"
title="$5"
furl="$6"
new_url="$7"

homepage="www.gov.uk$furl"
archive_link="http://webarchive.nationalarchives.gov.uk/$tna_timestamp/http://$host"

#
#  generate 410 page
#
cat <<"EOF"
<?php
$location_suggested_links = array();
$query_suggested_links = array();
$archive_links = array();
$uri_without_slash = rtrim( $_SERVER['REQUEST_URI'], '/' );
EOF

# generated php files
maps=dist/maps/$site
for file in $maps/*.php
do
    if [ -f $file ] ; then
        echo "\n/* $file */"
        cat $file
    fi
done

cat <<"EOF"
?><!DOCTYPE html>
<html class="no-branding">
  <head>
    <meta charset="utf-8">
    <title>This page has been archived</title>
    <meta name="viewport" content="width=device-width, initial-scale=1"> 
    <!--[if lt IE 9]>
    <script src="https://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
    <link href="/gone.css" media="screen" rel="stylesheet" type="text/css">
  </head>
EOF
cat <<EOF
  <body>
    <section id="content" role="main" class="group">
      <div class="gone-container">
        <header class="page-header group $site">
          <div class="legacy-site-logo"></div>
          <hgroup>
            <h1>The $title website has been replaced</h1>
          </hgroup>
        </header>

        <article role="article" class="group">

          <p>On $redirection_date the $title website was replaced by <a href='$new_url'>$homepage</a>.</p>
          <p><a href='https://www.gov.uk'>GOV.UK</a> is now the best place to find essential government services and information.</p>
EOF
cat <<EOF
<?php
  \$archive_link = '$archive_link' . \$_SERVER['REQUEST_URI'];
EOF
cat <<"EOF"

  if (isset($archive_links[$uri_without_slash])) {
      $archive_link = $archive_links[$uri_without_slash];
  }

  preg_match( "/dg_\d+/i", $uri_without_slash, $matches );
  if (isset($matches[0])) {
      $match = strtolower($matches[0]);
      if (isset( $archive_links[$match])) {
          $archive_link = $archive_links[$match];
      }
  }
?>
EOF
cat <<EOF
          <p>A copy of the page you were looking for may be found in <a href="<?= \$archive_link ?>">The National Archives</a>, however it will not be updated after $redirection_date.</p>
EOF
cat <<"EOF"
<?php

if ( isset( $location_suggested_link[$uri_without_slash] ) ) {
    $suggested_link = $location_suggested_link[$uri_without_slash];
}

preg_match( "/(item|topic)id=\d+/i", $uri_without_slash, $matches );
if ( isset($matches[0]) && isset($query_suggested_link[$matches[0]]) ) {
    $suggested_link = $query_suggested_link[$matches[0]];
}

preg_match( "/dg_\d+/i", $uri_without_slash, $matches );
if ( isset($matches[0]) ) {
    $match = strtolower($matches[0]);
    if ( isset( $location_suggested_link[$match] ) ) {
        $suggested_link = $location_suggested_link[$match];
    }
}

if ( isset($suggested_link) ) {
    echo "<p>For more information on this topic you may want to visit $suggested_link.</p>";
}

?>
        </article>
      </div>
    </section>
  </body>
</html>
EOF

exit 0