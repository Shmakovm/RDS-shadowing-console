# RDS shadowing console
# Mikhail Shmakov
# shmakovm@gmail.com

Add-Type -assembly System.Windows.Forms
Add-Type –AssemblyName System.Drawing


# RDS severs list
$RDSlist = @("TS4","TS5","TS6","TS10","TS11","TS12","TS13","TS14","TS19")


# Prepare Form
$Header = "SESSION NAME", "USER NAME", "ID", "STATUS", "IDLE TIME", "CONNECT DATE", "CONNECT TIME", "SERVER"
$dlgForm = New-Object System.Windows.Forms.Form
$dlgForm.Text ='Remote Desktop Shadowing'
$dlgForm.Width = 650
$dlgForm.Height = 700
$dlgForm.AutoSize = $true
$dlgForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$dlgForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$dlgForm.KeyPreview = $true

$StatusBar = New-Object System.Windows.Forms.StatusBar
$StatusBar.Height = 22
$StatusBar.Width = 200
$StatusBar.Location = New-Object System.Drawing.Point( 0, 250 )
    $StatusBarPan1 = New-Object System.Windows.Forms.StatusBarPanel
    $StatusBarPan2 = New-Object System.Windows.Forms.StatusBarPanel
    $StatusBarPan1.BorderStyle = 3 #[System.Windows.Forms.StatusBarPanel.StatusBarPanelBorderStyle]::Sunken
    $StatusBarPan1.AutoSize = 2 #[System.Windows.Forms.StatusBarPanel.StatusBarPanelAutoSize]::Spring
    $StatusBarPan1.Text = "Working..."
    $StatusBarPan2.Text = "F5 - Refresh"
    $StatusBarPan2.BorderStyle = 3 #[System.Windows.Forms.StatusBarPanel.StatusBarPanelBorderStyle]::Raised
    $StatusBarPan2.AutoSize = 3 #[System.Windows.Forms.StatusBarPanel.StatusBarPanelAutoSize]::Contents
    $StatusBarPan2.Alignment = 2
$StatusBar.ShowPanels = $true
$StatusBar.Panels.Add($StatusBarPan1) | Out-Null
$StatusBar.Panels.Add($StatusBarPan2) | Out-Null
$dlgForm.Controls.Add($StatusBar)

$dlglabel = New-Object System.Windows.Forms.Label
$dlglabel.Location = New-Object System.Drawing.Point(200,14)
$dlglabel.Text = 'Find User:'
$dlglabel.AutoSize = $true
$dlgForm.Controls.Add($dlglabel)

$dlgSearchText = New-Object System.Windows.Forms.TextBox
$dlgSearchText.Location = New-Object System.Drawing.Point(260, 11)
$dlgSearchText.Width = 200
$dlgSearchText.Height = 60
$dlgForm.Controls.Add($dlgSearchText)

$dlgBttn = New-Object System.Windows.Forms.Button
$dlgBttn.Text = 'Control'
$dlgBttn.AutoSize = $true
$dlgBttn.Location = New-Object System.Drawing.Point(15,10)
$dlgForm.Controls.Add($dlgBttn)

$dlgBttn2 = New-Object System.Windows.Forms.Button
$dlgBttn2.Text = 'View'
$dlgBttn2.AutoSize = $true
$dlgBttn2.Location = New-Object System.Drawing.Point(100,10)
$dlgForm.Controls.Add($dlgBttn2)


$dlgList = New-Object System.Windows.Forms.ListView
$dlgList.Location = New-Object System.Drawing.Point(0,50)
$dlgList.Width = $dlgForm.ClientRectangle.Width
$dlgList.Height = $dlgForm.ClientRectangle.Height - 72
$dlgList.Anchor = "Top, Left, Right, Bottom"
$dlgList.MultiSelect = $False
$dlgList.AllowColumnReorder = $true
$dlgList.View = 'Details'
$dlgList.FullRowSelect = 1;
$dlgList.GridLines = 1
$dlgList.Scrollable = 1
$dlgForm.Controls.add($dlgList)


function GetActiveSession {
    foreach ($RDSrv in $RDSlist) {
        $(quser.exe /server:$RDSrv | select-string rdp-) -replace "^[\s>]" , "" -replace "\s+" , "," | ConvertFrom-Csv -Header $Header | ForEach-Object {
        $dlgListItem = New-Object System.Windows.Forms.ListViewItem($_.'USER NAME')
        $dlgListItem.Subitems.Add($_.'SESSION NAME') | Out-Null
        $dlgListItem.Subitems.Add($_.ID) | Out-Null
        $dlgListItem.Subitems.Add($_.STATUS) | Out-Null
        $dlgListItem.Subitems.Add($_.'IDLE TIME') | Out-Null
        $dlgListItem.Subitems.Add($_.'CONNECT DATE') | Out-Null
        $dlgListItem.Subitems.Add($_.'CONNECT TIME') | Out-Null
        $dlgListItem.Subitems.Add($RDSrv) | Out-Null
        $dlgList.Items.Add($dlgListItem) | Out-Null
        }
    }
    
    $dlgSearchText.Clear()
    $StatusBarPan1.Text = "Total sessions: " + $dlgList.Items.Count
}


# Sorting by Column
function SortListView {
    param( [System.Windows.Forms.ListView]$sender, $column )

    $temp = $sender.Items | Foreach-Object { $_ }
    $Script:SortingDescending = !$Script:SortingDescending
    $sender.Items.Clear()
    $sender.ShowGroups = $false
    $sender.Sorting = 'none'
    $sender.Items.AddRange(($temp | Sort-Object -Descending:$script:SortingDescending -Property @{ Expression={ $_.SubItems[$column].Text } }))
}


function SortByUserName {
    $templist = $dlgList.Items | Foreach-Object { $_ }
    $dlgList.Items.Clear()
    $dlgList.Items.AddRange(($templist | Sort-Object -Property @{ Expression={ $_.SubItems[1].Text } }))
}


function ShadowRDSSession {
    param( [INT]$cs = 0 )

    $SelectedItem = $dlgList.SelectedItems[0]
    if ($SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Select a session to connect.",'',0,'Warning')
    } else {
        $session_id = $SelectedItem.subitems[2].text
        $session_srv = $SelectedItem.subitems[7].text
        if ( $cs -eq 1) {
            $(mstsc /v $session_srv /shadow:$session_id /control /noConsentPrompt)
        } else {
            $(mstsc /v $session_srv /shadow:$session_id /noConsentPrompt)
        }
    }
}


# Control Button Click
$dlgBttn.Add_Click(
{ ShadowRDSSession 1 }
)


# View Button Click
$dlgBttn2.Add_Click(
{ ShadowRDSSession 0 }
)


# Column Click
$dlgList.add_ColumnClick(
    {SortListView $this $_.Column}
)

# Mouse Double Click
$dlgList.add_DoubleClick(
    { ShadowRDSSession 1 }
)


# ListView focused
$dlgList.add_Enter(
    {
        foreach ($item in $dlgList.Items) {
            $item.BackColor = [System.Drawing.SystemColors]::Window
            $item.ForeColor = [System.Drawing.SystemColors]::WindowText
        }
    }
)


$dlgForm.Add_KeyDown(
    {
        if ($_.KeyCode -eq "Enter") {
            ShadowRDSSession 1 }

        if ($_.KeyCode -eq "F5") {
            $dlgList.Items.Clear()
            GetActiveSession
            SortByUserName
        }

        if ($_.KeyCode -eq "Escape") {
            $dlgSearchText.Clear()
        }
    }
)


# Search box edit (find user)
$dlgSearchText.add_TextChanged(
{
   if ($dlgSearchText.Text -ne "") {
        for ($i = $dlgList.Items.Count - 1; $i -ge 0; $i--) {
            $item = $dlgList.Items[$i]
            if ($item.SubItems[1].Text.ToLower().StartsWith($dlgSearchText.Text.ToLower())) {
                $item.BackColor = [System.Drawing.SystemColors]::Highlight
                $item.ForeColor = [System.Drawing.SystemColors]::HighlightText
                $item.Selected = $true
                $dlgList.EnsureVisible($i)
            } else {
#                $dlgList.Items.Remove($item)
                $item.BackColor = [System.Drawing.SystemColors]::Window
                $item.ForeColor = [System.Drawing.SystemColors]::WindowText
            }
        }
    } else {
         foreach ($item in $dlgList.Items) {
              $item.BackColor = [System.Drawing.SystemColors]::Window
              $item.ForeColor = [System.Drawing.SystemColors]::WindowText
        }
         $dlgList.Items[0].Selected = $true
         $dlgList.EnsureVisible(0)
         $dlgList.SelectedItems.Clear()
    }
}
)


# Main()
# Add columns to the ListView
foreach ($column in $Header) { $dlgList.Columns.Add($column) | Out-Null }

GetActiveSession

$dlgList.AutoResizeColumns(1)

SortByUserName

$dlgForm.ShowDialog()
