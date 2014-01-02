class oxid::stages {
  stage { 'pre': before => Stage['main'] }

  stage { 'system':
    require => Stage['pre'],
    before  => Stage['main']
  }
}