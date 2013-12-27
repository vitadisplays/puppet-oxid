class oxid::apt {
  class { '::apt': }
  
  Exec["apt_update"] -> Package <| |>
}