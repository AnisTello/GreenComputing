@REM powerapi-iagl launcher script
@REM
@REM Environment:
@REM JAVA_HOME - location of a JDK home dir (optional if java on path)
@REM CFG_OPTS  - JVM options (optional)
@REM Configuration:
@REM POWERAPI_IAGL_config.txt found in the POWERAPI_IAGL_HOME.
@setlocal enabledelayedexpansion

@echo off

if "%POWERAPI_IAGL_HOME%"=="" set "POWERAPI_IAGL_HOME=%~dp0\\.."

set "APP_LIB_DIR=%POWERAPI_IAGL_HOME%\lib\"

rem Detect if we were double clicked, although theoretically A user could
rem manually run cmd /c
for %%x in (!cmdcmdline!) do if %%~x==/c set DOUBLECLICKED=1

rem FIRST we load the config file of extra options.
set "CFG_FILE=%POWERAPI_IAGL_HOME%\POWERAPI_IAGL_config.txt"
set CFG_OPTS=
if exist %CFG_FILE% (
  FOR /F "tokens=* eol=# usebackq delims=" %%i IN ("%CFG_FILE%") DO (
    set DO_NOT_REUSE_ME=%%i
    rem ZOMG (Part #2) WE use !! here to delay the expansion of
    rem CFG_OPTS, otherwise it remains "" for this loop.
    set CFG_OPTS=!CFG_OPTS! !DO_NOT_REUSE_ME!
  )
)

rem We use the value of the JAVACMD environment variable if defined
set _JAVACMD=%JAVACMD%

if "%_JAVACMD%"=="" (
  if not "%JAVA_HOME%"=="" (
    if exist "%JAVA_HOME%\bin\java.exe" set "_JAVACMD=%JAVA_HOME%\bin\java.exe"
  )
)

if "%_JAVACMD%"=="" set _JAVACMD=java

rem Detect if this java is ok to use.
for /F %%j in ('"%_JAVACMD%" -version  2^>^&1') do (
  if %%~j==java set JAVAINSTALLED=1
  if %%~j==openjdk set JAVAINSTALLED=1
)

rem BAT has no logical or, so we do it OLD SCHOOL! Oppan Redmond Style
set JAVAOK=true
if not defined JAVAINSTALLED set JAVAOK=false

if "%JAVAOK%"=="false" (
  echo.
  echo A Java JDK is not installed or can't be found.
  if not "%JAVA_HOME%"=="" (
    echo JAVA_HOME = "%JAVA_HOME%"
  )
  echo.
  echo Please go to
  echo   http://www.oracle.com/technetwork/java/javase/downloads/index.html
  echo and download a valid Java JDK and install before running powerapi-iagl.
  echo.
  echo If you think this message is in error, please check
  echo your environment variables to see if "java.exe" and "javac.exe" are
  echo available via JAVA_HOME or PATH.
  echo.
  if defined DOUBLECLICKED pause
  exit /B 1
)


rem We use the value of the JAVA_OPTS environment variable if defined, rather than the config.
set _JAVA_OPTS=%JAVA_OPTS%
if "!_JAVA_OPTS!"=="" set _JAVA_OPTS=!CFG_OPTS!

rem We keep in _JAVA_PARAMS all -J-prefixed and -D-prefixed arguments
rem "-J" is stripped, "-D" is left as is, and everything is appended to JAVA_OPTS
set _JAVA_PARAMS=
set _APP_ARGS=

:param_loop
call set _PARAM1=%%1
set "_TEST_PARAM=%~1"

if ["!_PARAM1!"]==[""] goto param_afterloop


rem ignore arguments that do not start with '-'
if "%_TEST_PARAM:~0,1%"=="-" goto param_java_check
set _APP_ARGS=!_APP_ARGS! !_PARAM1!
shift
goto param_loop

:param_java_check
if "!_TEST_PARAM:~0,2!"=="-J" (
  rem strip -J prefix
  set _JAVA_PARAMS=!_JAVA_PARAMS! !_TEST_PARAM:~2!
  shift
  goto param_loop
)

if "!_TEST_PARAM:~0,2!"=="-D" (
  rem test if this was double-quoted property "-Dprop=42"
  for /F "delims== tokens=1,*" %%G in ("!_TEST_PARAM!") DO (
    if not ["%%H"] == [""] (
      set _JAVA_PARAMS=!_JAVA_PARAMS! !_PARAM1!
    ) else if [%2] neq [] (
      rem it was a normal property: -Dprop=42 or -Drop="42"
      call set _PARAM1=%%1=%%2
      set _JAVA_PARAMS=!_JAVA_PARAMS! !_PARAM1!
      shift
    )
  )
) else (
  if "!_TEST_PARAM!"=="-main" (
    call set CUSTOM_MAIN_CLASS=%%2
    shift
  ) else (
    set _APP_ARGS=!_APP_ARGS! !_PARAM1!
  )
)
shift
goto param_loop
:param_afterloop

set _JAVA_OPTS=!_JAVA_OPTS! !_JAVA_PARAMS!
:run
 
set "APP_CLASSPATH=%APP_LIB_DIR%\powerapi-iagl.powerapi-iagl-3.3.jar;%APP_LIB_DIR%\org.powerapi.powerapi-core-3.3.jar;%APP_LIB_DIR%\ancillary.jar;%APP_LIB_DIR%\fusejna.jar;%APP_LIB_DIR%\libancillary.so;%APP_LIB_DIR%\libpfm.jar;%APP_LIB_DIR%\libpfm.so;%APP_LIB_DIR%\libsigar-amd64-freebsd-6.so;%APP_LIB_DIR%\libsigar-amd64-linux.so;%APP_LIB_DIR%\libsigar-amd64-solaris.so;%APP_LIB_DIR%\libsigar-arm-linux.so;%APP_LIB_DIR%\libsigar-ia64-linux.so;%APP_LIB_DIR%\libsigar-ppc-aix-5.so;%APP_LIB_DIR%\libsigar-ppc-linux.so;%APP_LIB_DIR%\libsigar-ppc64-aix-5.so;%APP_LIB_DIR%\libsigar-ppc64-linux.so;%APP_LIB_DIR%\libsigar-s390x-linux.so;%APP_LIB_DIR%\libsigar-sparc-solaris.so;%APP_LIB_DIR%\libsigar-sparc64-solaris.so;%APP_LIB_DIR%\libsigar-x86-freebsd-5.so;%APP_LIB_DIR%\libsigar-x86-freebsd-6.so;%APP_LIB_DIR%\libsigar-x86-linux.so;%APP_LIB_DIR%\libsigar-x86-solaris.so;%APP_LIB_DIR%\sigar-amd64-winnt.dll;%APP_LIB_DIR%\sigar-x86-winnt.dll;%APP_LIB_DIR%\ancillary.jar;%APP_LIB_DIR%\fusejna.jar;%APP_LIB_DIR%\libancillary.so;%APP_LIB_DIR%\libpfm.jar;%APP_LIB_DIR%\libpfm.so;%APP_LIB_DIR%\libsigar-amd64-freebsd-6.so;%APP_LIB_DIR%\libsigar-amd64-linux.so;%APP_LIB_DIR%\libsigar-amd64-solaris.so;%APP_LIB_DIR%\libsigar-arm-linux.so;%APP_LIB_DIR%\libsigar-ia64-linux.so;%APP_LIB_DIR%\libsigar-ppc-aix-5.so;%APP_LIB_DIR%\libsigar-ppc-linux.so;%APP_LIB_DIR%\libsigar-ppc64-aix-5.so;%APP_LIB_DIR%\libsigar-ppc64-linux.so;%APP_LIB_DIR%\libsigar-s390x-linux.so;%APP_LIB_DIR%\libsigar-sparc-solaris.so;%APP_LIB_DIR%\libsigar-sparc64-solaris.so;%APP_LIB_DIR%\libsigar-x86-freebsd-5.so;%APP_LIB_DIR%\libsigar-x86-freebsd-6.so;%APP_LIB_DIR%\libsigar-x86-linux.so;%APP_LIB_DIR%\libsigar-x86-solaris.so;%APP_LIB_DIR%\sigar-amd64-winnt.dll;%APP_LIB_DIR%\sigar-x86-winnt.dll;%APP_LIB_DIR%\org.scala-lang.scala-library-2.11.7.jar;%APP_LIB_DIR%\org.apache.logging.log4j.log4j-api-2.3.jar;%APP_LIB_DIR%\org.apache.logging.log4j.log4j-core-2.3.jar;%APP_LIB_DIR%\com.typesafe.akka.akka-actor_2.11-2.3.14.jar;%APP_LIB_DIR%\com.typesafe.config-1.2.1.jar;%APP_LIB_DIR%\fr.inria.powerspy.powerspy-core_2.11-1.2.jar;%APP_LIB_DIR%\com.nativelibs4java.bridj-0.7.0.jar;%APP_LIB_DIR%\com.google.android.tools.dx-1.7.jar;%APP_LIB_DIR%\com.github.scala-incubator.io.scala-io-core_2.11-0.4.3.jar;%APP_LIB_DIR%\org.scala-lang.modules.scala-parser-combinators_2.11-1.0.1.jar;%APP_LIB_DIR%\com.madgag.scala-arm_2.11-1.3.3.jar;%APP_LIB_DIR%\org.scala-lang.plugins.scala-continuations-library_2.11-1.0.1.jar;%APP_LIB_DIR%\com.github.scala-incubator.io.scala-io-file_2.11-0.4.3.jar;%APP_LIB_DIR%\org.jfree.jfreechart-1.0.19.jar;%APP_LIB_DIR%\org.jfree.jcommon-1.0.23.jar;%APP_LIB_DIR%\org.scala-saddle.saddle-core_2.11-1.3.3.jar;%APP_LIB_DIR%\org.joda.joda-convert-1.2.jar;%APP_LIB_DIR%\org.scala-saddle.google-rfc-2445-20110304.jar;%APP_LIB_DIR%\com.googlecode.efficient-java-matrix-library.ejml-0.19.jar;%APP_LIB_DIR%\org.apache.commons.commons-math-2.2.jar;%APP_LIB_DIR%\it.unimi.dsi.fastutil-6.5.4.jar;%APP_LIB_DIR%\it.unimi.dsi.dsiutils-2.0.15.jar;%APP_LIB_DIR%\com.martiansoftware.jsap-2.1.jar;%APP_LIB_DIR%\com.google.guava.guava-14.0-rc3.jar;%APP_LIB_DIR%\org.slf4j.slf4j-api-1.7.2.jar;%APP_LIB_DIR%\ch.qos.logback.logback-classic-1.0.9.jar;%APP_LIB_DIR%\ch.qos.logback.logback-core-1.0.9.jar;%APP_LIB_DIR%\log4j.log4j-1.2.17.jar;%APP_LIB_DIR%\commons-configuration.commons-configuration-1.8.jar;%APP_LIB_DIR%\commons-lang.commons-lang-2.6.jar;%APP_LIB_DIR%\commons-logging.commons-logging-1.1.1.jar;%APP_LIB_DIR%\commons-io.commons-io-2.4.jar;%APP_LIB_DIR%\commons-collections.commons-collections-3.2.1.jar;%APP_LIB_DIR%\org.apache.commons.commons-math3-3.1.1.jar;%APP_LIB_DIR%\org.hyperic.sigar-1.6.5.132.jar;%APP_LIB_DIR%\io.spray.spray-can_2.11-1.3.3.jar;%APP_LIB_DIR%\io.spray.spray-io_2.11-1.3.3.jar;%APP_LIB_DIR%\io.spray.spray-util_2.11-1.3.3.jar;%APP_LIB_DIR%\io.spray.spray-http_2.11-1.3.3.jar;%APP_LIB_DIR%\org.parboiled.parboiled-scala_2.11-1.1.7.jar;%APP_LIB_DIR%\org.parboiled.parboiled-core-1.1.7.jar;%APP_LIB_DIR%\io.spray.spray-client_2.11-1.3.3.jar;%APP_LIB_DIR%\io.spray.spray-httpx_2.11-1.3.3.jar;%APP_LIB_DIR%\org.scala-lang.modules.scala-xml_2.11-1.0.3.jar;%APP_LIB_DIR%\org.jvnet.mimepull.mimepull-1.9.5.jar;%APP_LIB_DIR%\io.spray.spray-routing_2.11-1.3.3.jar;%APP_LIB_DIR%\com.chuusai.shapeless_2.11-1.2.4.jar;%APP_LIB_DIR%\io.spray.spray-json_2.11-1.3.2.jar;%APP_LIB_DIR%\com.github.nscala-time.nscala-time_2.11-2.0.0.jar;%APP_LIB_DIR%\joda-time.joda-time-2.7.jar;%APP_LIB_DIR%\net.java.dev.jna.jna-4.1.0.jar;%APP_LIB_DIR%\com.github.jnr.jnr-unixsocket-0.8.jar;%APP_LIB_DIR%\com.github.jnr.jnr-ffi-2.0.3.jar;%APP_LIB_DIR%\com.github.jnr.jffi-1.2.9-native.jar;%APP_LIB_DIR%\com.github.jnr.jffi-1.2.9.jar;%APP_LIB_DIR%\org.ow2.asm.asm-5.0.3.jar;%APP_LIB_DIR%\org.ow2.asm.asm-commons-5.0.3.jar;%APP_LIB_DIR%\org.ow2.asm.asm-tree-5.0.3.jar;%APP_LIB_DIR%\org.ow2.asm.asm-analysis-5.0.3.jar;%APP_LIB_DIR%\org.ow2.asm.asm-util-5.0.3.jar;%APP_LIB_DIR%\com.github.jnr.jnr-x86asm-1.0.2.jar;%APP_LIB_DIR%\com.github.jnr.jnr-constants-0.8.7.jar;%APP_LIB_DIR%\com.github.jnr.jnr-enxio-0.9.jar;%APP_LIB_DIR%\com.github.jnr.jnr-posix-3.0.12.jar;%APP_LIB_DIR%\..\conf"
set "APP_MAIN_CLASS=Application"

if defined CUSTOM_MAIN_CLASS (
    set MAIN_CLASS=!CUSTOM_MAIN_CLASS!
) else (
    set MAIN_CLASS=!APP_MAIN_CLASS!
)

rem Call the application and pass all arguments unchanged.
"%_JAVACMD%" !_JAVA_OPTS! !POWERAPI_IAGL_OPTS! -cp "%APP_CLASSPATH%" %MAIN_CLASS% !_APP_ARGS!

@endlocal


:end

exit /B %ERRORLEVEL%
