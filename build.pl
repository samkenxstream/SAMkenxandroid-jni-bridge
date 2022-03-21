#!/usr/bin/env perl -w
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path($0));

use PrepareAndroidSDK;
use File::Path;
use strict;
use warnings;

my $api = "android-31";

my @classes = (
	'::android::Manifest_permission',
	'::android::R_attr',
	'::android::app::Activity',
	'::android::app::AlertDialog_Builder',
	'::android::app::NotificationManager',
	'::android::app::Presentation',
	'::android::content::Context',
	'::android::graphics::Color',
	'::android::graphics::ImageFormat',
	'::android::graphics::drawable::ColorDrawable',
	'::android::hardware::display::DisplayManager',
	'::android::hardware::Camera',
	'::android::hardware::input::InputManager',
	'::android::hardware::GeomagneticField',
	'::android::location::LocationManager',
	'::android::media::AudioAttributes_Builder',
	'::android::media::AudioFocusRequest_Builder',
	'::android::media::AudioManager',
	'::android::media::MediaCodec',
	'::android::media::MediaCodec::BufferInfo',
	'::android::media::MediaExtractor',
	'::android::media::MediaFormat',
	'::android::media::MediaRouter',
	'::android::net::ConnectivityManager',
	'::android::net::wifi::WifiManager',
	'::android::os::Build',
	'::android::os::Build_VERSION',
	'::android::os::HandlerThread',
	'::android::os::Environment',
	'::android::os::PowerManager',
	'::android::os::Process',
	'::android::os::Vibrator',
	'::android::provider::Settings_Secure',
	'::android::provider::Settings_System',
	'::android::telephony::TelephonyManager',
	'::android::telephony::SubscriptionManager',
	'::android::telephony::SubscriptionInfo',
	'::android::view::Choreographer',
	'::android::view::Display',
	'::android::view::Gravity',
	'::android::view::SurfaceView',
	'::android::view::WindowManager',
	'::android::webkit::MimeTypeMap',
	'::android::widget::CheckBox',
	'::android::widget::CompoundButton_OnCheckedChangeListener',
	'::android::widget::ProgressBar',
	'::java::lang::Character',
	'::java::lang::System',
	'::java::lang::SecurityException',
	'::java::lang::NoSuchMethodError',
	'::java::lang::ClassCastException',
	'::java::lang::UnsatisfiedLinkError',
	'::java::io::FileNotFoundException',
	'::java::net::HttpURLConnection',
	'::java::nio::channels::Channels',
	'::java::util::HashSet',
	'::java::util::Map_Entry',
	'::java::util::NoSuchElementException',
	'::java::util::Scanner',
	'::java::util::zip::ZipFile',
	'::javax::net::ssl::X509TrustManager',
	'::javax::net::ssl::TrustManagerFactory',
	'::java::security::KeyStore',

	'::com::google::android::gms::ads::identifier::AdvertisingIdClient',
	'::com::google::android::gms::common::GooglePlayServicesAvailabilityException',
	'::com::google::android::gms::common::GooglePlayServicesNotAvailableException',
);

# Set ANDROID_SDK_ROOT
sub Prepare
{
	my $class_names = join(' ', @classes);
	my $threads = 8;

    PrepareAndroidSDK::GetAndroidSDK("$api", "21", "froyo", "r21", "24");

    #system("make clean") && die("Clean failed");
    #system("make api-source PLATFORM=android APINAME=\"$api\" APICLASSES=\"$class_names\"") && die("Failed to make API source");
    #system("make api-module PLATFORM=android APINAME=\"$api\" APICLASSES=\"$class_names\"") && die("Failed to make API module");
    #system("make compile-static-apilib -j$threads PLATFORM=android ABI=armeabi-v7a APINAME=\"$api\" APICLASSES=\"$class_names\"") && die("Failed to make android armv7 library");
    #system("make compile-static-apilib -j$threads PLATFORM=android ABI=arm64-v8a   APINAME=\"$api\" APICLASSES=\"$class_names\"") && die("Failed to make android arm64 library");
    #system("make compile-static-apilib -j$threads PLATFORM=android ABI=x86         APINAME=\"$api\" APICLASSES=\"$class_names\"") && die("Failed to make android x86 library");
    #system("make compile-static-apilib -j$threads PLATFORM=android ABI=x86_64      APINAME=\"$api\" APICLASSES=\"$class_names\"") && die("Failed to make android x86_64 library");
}

sub ZipIt
{
	system("mkdir -p build/temp/include") && die("Failed to create temp directory.");

	# write build info
	my $git_info = "$ENV{GIT_BRANCH}\n$ENV{GIT_REVISION}\n$ENV{GIT_REPOSITORY_URL}";
	open(BUILD_INFO_FILE, '>', "build/temp/build.txt") or die("Unable to write build information to build/temp/build.txt");
	print BUILD_INFO_FILE "$git_info";
	close(BUILD_INFO_FILE);

	# create zip
	system("cp build/$api/source/*.h build/temp/include") && die("Failed to copy headers.");
	system("cd build && jar cf temp/jnibridge.jar bitter") && die("Failed to create java class archive.");
	system("cd build/$api && zip ../builds.zip -r android/*/*.a") && die("Failed to package libraries into zip file.");
	system("cd build/temp && zip ../builds.zip -r build.txt jnibridge.jar include") && die("Failed to package zip file.");
	system("rm -r build/temp") && die("Unable to remove temp directory.");
}

my $stringBuildJniBridgeAndZipIt = "Build JNIBridge and Zip It";
my $stringBuildJniBridge = "Build JNIBridge";
my $stringGenerateVSProjectFiles = "Generate Visual Studio project files";
my $stringTestOnOSX = "Test JNIBridge";
my $stringHelp = "Show command line arguments";
my @abis = ("armeabi-v7a", "arm64-v8a", "x86", "x86_64");     

sub ShowMenu
{
	print("(b) ${stringBuildJniBridgeAndZipIt}\n");
	foreach my $abi ( @abis ) 
	{
		print("(b $abi) ${stringBuildJniBridge} $abi\n");
	}

	print("(p) ${stringGenerateVSProjectFiles}\n");
	print("(t) ${stringTestOnOSX}\n");
	print("(h) ${stringHelp}\n");
	print("(q) Exit\n");
	print("\n");
}

sub ShowCommandLineArgs
{
	print("build.pl jnibridge\n    ${stringBuildJniBridgeAndZipIt}\n\n");
	foreach my $abi ( @abis ) 
	{
		print("build.pl jnibridge $abi\n    ${stringBuildJniBridge} $abi\n\n");
	}

	print("build.pl projectfiles\n    ${stringGenerateVSProjectFiles}\n\n");
	print("build.pl test\n    ${stringTestOnOSX}\n\n");
	print("build.pl help\n    ${stringHelp}\n\n");
}

sub GetBeeExecutable
{
    if (lc $^O eq 'darwin')
    {
        return "./bee";
    }
    elsif (lc $^O eq 'linux')
    {
        return "./bee";
    }
    elsif (lc $^O eq 'mswin32')
    {
        return "bee";
    }
    else
    {
        die "Coudln't get Bee executable for " . $^O;
    }
}

my $Bee = GetBeeExecutable();
my ($arg1, $arg2) = @ARGV;
my $quitAfterCommand = 0;

while (1)
{
	if (not defined $arg1)
	{
		ShowMenu();
		my $pick = <STDIN>;
		
		if ($pick)
		{
			chomp($pick);
		}
		else
		{
			# null stdin probably means ctrl-c
			print("Ctrl + C detected, quitting\n");
			$pick = "q";
		}
		
		if ($pick eq "b")
		{
			$arg1 = "jnibridge";
		}

		foreach my $abi ( @abis ) 
		{
			if ($pick eq "b $abi")
			{
				$arg1 = "jnibridge";
				$arg2 = $abi;
			}
		}
	

		if ($pick eq "p")
		{
			$arg1 = "projectfiles";
		}
		if ($pick eq "t")
		{
			$arg1 = "test";
		}
		if ($pick eq "h")
		{
			$arg1 = "help";
		}
		if ($pick eq "q")
		{
			$arg1 = "quit";
		}
		
		if (not defined $arg1)
		{
			$arg1 = "unknownshortcut";
			$arg2 = "Unknown command '${pick}'";
		}
		
		$quitAfterCommand = 0;
	}
	else
	{
		$quitAfterCommand = 1;
	}


	print("\nArguments:\n    ${arg1}");
	if (defined $arg2)
	{
		print(" $arg2");
	}
	print("\n\n");
	
	if ($arg1 eq "jnibridge")
	{
		print("Building JNIBridge\n");
		Prepare();
		if (not defined $arg2)
		{
			system("${Bee} build:android:zip") && die("Couldn't build JNIBridge");
		}
		else
		{
			my $foundCorrectABI = 0;
			foreach my $abi ( @abis ) 
			{
				if ($arg2 eq $abi)
				{
					$foundCorrectABI = 1;
					system("${Bee} build:android:${arg2}") && die("Couldn't build JNIBridge ${arg2}");
				}
			}
			
			if (not $foundCorrectABI)
			{
				print("Unknown jnibridge ABI '${arg2}'");
			}
		}
		
	}
	elsif ($arg1 eq "projectfiles")
	{
		print("Generating Visual Studio Projects JNIBridge\n");
		Prepare();
		system("${Bee} projectfiles") && die("Couldn't generate Visual Studio project files");
	}
	elsif ($arg1 eq "test")
	{
		print("Building and testing JNIBridge\n");
		Prepare();
		
		if (lc $^O eq 'darwin')
		{
			system("${Bee} build:osx:test") && die("Couldn't build JNIBridge for testing");
			system("./build/osx/JNIBridgeTests") && die("Test failed");
		}
		elsif (lc $^O eq 'mswin32')
		{
			system("${Bee} build:windows:test") && die("Couldn't build JNIBridge for testing");
			system("build\\windows\\runtests.cmd") && die("Test failed");
		}
	}
	elsif ($arg1 eq "help")
	{
		ShowCommandLineArgs();
	}
	elsif ($arg1 eq "quit")
	{
		exit();
	}
	elsif ($arg1 eq "unknownshortcut")
	{
		print($arg2);
	}
	else
	{
		die("Unknown command ${arg1}\n");
	}
	
	
	print("\n\nCommand finished.\n\n");
	
	if ($quitAfterCommand)
	{
		exit();
	}
	
	$arg1 = undef();
	$arg2 = undef();
}

