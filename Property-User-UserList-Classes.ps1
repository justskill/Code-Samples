<#======================================

Script Name: Property-User-UserList-Classes.ps1
Written By: Mitchell Skillman
Script Version: 1.2
PowerShell Version: ---

======================================#>

<#======================================

.SYNOPSIS
    A set of custom object to be used with ****** to generate pre-formatted lists of users
    to be imported into the system.
.DESCRIPTION
    A set of custom object to be used with ****** to generate pre-formatted lists of users
    to be imported into the system.   
.PARAMETER
    Property(Name, Mandatory, Order)

    Internal object used by the User class
.PARAMETER
    User(FirstName, LastName, Email, UserName, CostCenter, EmployeeId, Department, WidChain, Title, ManagerLevel)

    Internal object used by the UserList class
.PARAMETER
    UserList()

    Default instantiation
.PARAMETER
    UserList(SearchBase)

    Custom searchbase for the AD query
.EXAMPLE
    $UserList = [userlist]::new()

======================================#>

# Property class.  This is to track the properties fields for EZOffice Upload
class property {
    [string] $Name;
    [bool]   $Mandatory;
    [int]    $Order;
    [string] $Value;

    # Our base constructor.  Our 'User' class will determine the name, required, and order members.
    property([string]$Name, [bool]$Mandatory=$false, [int]$Order) {
        $this.Name      = $Name;
        $this.Mandatory = $Mandatory;
        $this.order     = $Order;
    }
}

# User class.  This is to track all attributes for a given user and their relation to the excel sheet to upload.
class User {
    # We're statically assigning the first 3 values of our property members.  This is mapped to align with the excel spreadsheet.
    [property]$FirstName             = [property]::new("First Name",              $false, 0);
    [property]$LastName              = [property]::new("Last Name",               $true,  1);
    [property]$Email                 = [property]::new("Email",                   $false, 2);
    [property]$Role                  = [property]::new("Role",                    $true,  3);
    [property]$UserListing           = [property]::new("User Listing",            $false, 4);
    [property]$IdentificationNumber  = [property]::new("Identification Number",   $false, 5);
    [property]$Department            = [property]::new("Department",              $false, 6);
    [property]$LoginEnabled          = [property]::new("Login Enabled",           $false, 7);
    [property]$SubscribedToEmails    = [property]::new("Subscribed To Emails",    $false, 8);
    [property]$SkipConfirmationEmail = [property]::new("Skip Confirmation Email", $false, 9);
    [property]$Password              = [property]::new("Password",                $false, 10);
    [property]$AddressLine1          = [property]::new("Address Line 1",          $false, 11);
    [property]$AddressLine2          = [property]::new("Address Line 2",          $false, 12);
    [property]$City                  = [property]::new("City",                    $false, 13);
    [property]$State                 = [property]::new("State",                   $false, 14);
    [property]$ZipCode               = [property]::new("Zip Code",                $false, 15);
    [property]$Country               = [property]::new("Country",                 $false, 16);
    [property]$Description           = [property]::new("Description",             $false, 17);
    [property]$PhoneNumber           = [property]::new("Phone Number",            $false, 18);
    [property]$Fax                   = [property]::new("Fax",                     $false, 19);
    [property]$Customfield1          = [property]::new("Custom field 1*",         $false, 20);
    [property]$Customfield2          = [property]::new("Custom field 2*",         $false, 21);
    [property]$CostCenter            = [property]::new("Cost Center",             $false, 22);
    [property]$WidChain              = [property]::new("WID Chain",               $false, 23);
    [property]$Title                 = [property]::new("Title",                   $false, 24);
    [property]$ManagerLevel          = [property]::new("Manager Level",           $false, 25);

    $Attributes = @()

    # Our base constructor, so far we only need the first and last names, and the email address of the user.
    User($FirstName,$LastName,$Email,$UserName,$CostCenter,$EmployeeId,$Department,$WidChain,$Title,$ManagerLevel) {
        Try { $this.FirstName.Value            = $FirstName.trim()    } catch {}
        Try { $this.LastName.Value             = $LastName.trim()     } catch {}
        Try { $this.CostCenter.Value           = $CostCenter.trim()   } catch {}
        Try { $this.IdentificationNumber.Value = $EmployeeId.trim()   } catch {}
        Try { $this.Department.Value           = $Department.trim()   } catch {}
        Try { $this.WidChain.Value             = $WidChain.trim()     } catch {}
        Try { $this.Title.Value                = $Title.trim()        } catch {}
        Try { $this.ManagerLevel.Value         = $ManagerLevel.trim() } catch {}
        Try { $this.Email.Value                = $UserName.trim()     } catch {}


        # Default Values
        $this.Role.Value                  = 'Staff'
        $this.LoginEnabled.Value          = 'Yes'
        $this.SubscribedToEmails.Value    = 'No'
        $this.SkipConfirmationEmail.Value = 'Yes'
        $this.UserListing.value           = '*************'



        # Populate an array with our attributes to help with item iteration.
        # Note these are 'referenced' objects, so they will update if the attribute itself changes.
        $this.Attributes = @(
            $this.FirstName,
            $this.LastName,
            $this.Email,
            $this.Role,
            $this.UserListing,
            $this.IdentificationNumber,
            $this.Department,
            $this.LoginEnabled,
            $this.SubscribedToEmails,
            $this.SkipConfirmationEmail,
            $this.Password,
            $this.AddressLine1,
            $this.AddressLine2,
            $this.City,
            $this.State,
            $this.ZipCode,
            $this.Country,
            $this.Description,
            $this.PhoneNumber,
            $this.Fax,
            $this.Customfield1,
            $this.Customfield2,
            $this.CostCenter,
            $this.WidChain,
            $this.Title,
            $this.ManagerLevel
        )
    }
}

# UserList class.  This is to contain all users we want to sync, and to provide methods for aggregating and exporting them.
class UserList {

    $Users = @() # Our list of users as 'User' objects.  These are populated when we run the 'AggregateUsers' method
    $SearchBase = "***********************" # The OU structure that we will be looking at for populating users

    # GenerateCSV()   This funciton will iterate through the UserList and generate a CSV based on the users' Properties
    [void]GenerateCSV($path) {

        $Export = @() # An array of custom objects built for exporting to CSV

        foreach ($u in $this.Users) {
            $Columns = [ordered] @{
                FirstName             = $u.FirstName.value
                LastName              = $u.LastName.value
                Email                 = $u.Email.value
                Role                  = $u.Role.value
                UserListing           = $u.UserListing.value
                IdentificationNumber  = $u.IdentificationNumber.value
                Department            = $u.Department.value
                LoginEnabled          = $u.LoginEnabled.value
                SubscribedToEmails    = $u.SubscribedToEmails.value
                SkipConfirmationEmail = $u.SkipConfirmationEmail.value
                Password              = $u.Password.value
                AddressLine1          = $u.AddressLine1.value
                AddressLine2          = $u.AddressLine2.value
                City                  = $u.City.value
                State                 = $u.State.value
                ZipCode               = $u.ZipCode.value
                Country               = $u.Country.value
                Description           = $u.Description.value
                PhoneNumber           = $u.PhoneNumber.value
                Fax                   = $u.Fax.value
                Customfield1          = $u.Customfield1.value
                Customfield2          = $u.Customfield2.value
                CostCenter            = $u.CostCenter.value
                WidChain              = $u.WidChain.value
                Title                 = $u.Title.value
                ManagerLevel          = $u.ManagerLevel.value

            }
            $Export += New-Object PSObject -Property $columns      
        }
        $Export | export-csv -Path $path -NoTypeInformation
    }

    # AggregateUsers()  This function will gather all Active Directory users and generate 'User' objects for them with the properties we will be syncing.
    [void]AggregateUsers([bool]$Test) {
        # Clear property to prevent duplication
        $this.Users = @()

        if ($Test) {
             # Query for returning only desired test users
            $ADUsers = get-aduser -filter {employeeId -eq ***** -or employeeId -eq ***** -or employeeId -eq ****** -and enabled -eq $true} -Properties GivenName,Surname,mail,EmployeeID,Department,extensionAttribute11,Title,extensionAttribute2,departmentNumber
        }
        else {
            # Query for returning all desired users
            $ADUsers = get-aduser -SearchBase $this.SearchBase -filter { employeeId -ne -1 -and enabled -eq $true } -Properties GivenName,Surname,mail,EmployeeID,Department,extensionAttribute11,Title,extensionAttribute2,departmentNumber
        }

        # Populate our userlist
        foreach ($u in $ADUsers) {
            $TempUser = [User]::new($u.GivenName,
                                    $u.Surname,
                                    $u.mail,
                                    $u.UserPrincipalName,
                                    $u.departmentNumber,
                                    $u.EmployeeID,
                                    $u.Department,
                                    $u.extensionAttribute11,
                                    $u.Title,
                                    $u.extensionAttribute2)
            $this.Users += $TempUser
        }
    }

    # Delagating Method
    [void]AggregateUsers(){ $this.AggregateUsers($false) }

    # Default Constructor.  We don't need any input, so it is blank
    UserList() {
    }

    # Constructor for overwriting the 'Searchbase' property
    UserList([string]$SearchBase) {
        $this.SearchBase = $SearchBase
    }
}