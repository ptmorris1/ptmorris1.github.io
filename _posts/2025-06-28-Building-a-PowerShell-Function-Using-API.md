---
title: Building a PowerShell Function Using API
date: 2025-06-28 08:00:00 -0500
categories: [tutorial]
tags: [powershell,windows,api,DadJokes]
---
Let's have a little fun while learning, and create a PowerShell function that gets Dad jokes!  
We'll work through using a public API, then make a reusable function, and finally give it some cool upgrades.  
Ready? Let's go!

* * *

## ⚡ Prerequisites

*   **PowerShell 7+** (Why not use the latest and greatest? 🦾)

* * *

## Using the Dad Joke API

We'll use the free [icanhazdadjoke.com](https://icanhazdadjoke.com) API.  
Check out their [API docs](https://icanhazdadjoke.com/api) — it's super simple:  
**No authentication needed!** 🎉

* * *

## Step 1: Test the API with PowerShell

> UserAgent is Required!
> If you intend on using the icanhazdadjoke.com API, they _kindly ask_ that you set a custom `UserAgent` header for all requests.
> 
> - A good User-Agent should include your project/library name and a URL or email for contact.
> - **Example:** `UserAgent = "(myMail.mail.com)"`
> 
> **Be respectful of the site's free, no-auth access and always set a custom User-Agent!**
{: .prompt-warning }

Let’s set up our test call using **splatting** for cleaner parameters.  
We’ll use the `Invoke-RestMethod` cmdlet.

```powershell
$ApiParams = @{
    URI       = 'https://icanhazdadjoke.com/'
    Headers   = @{ accept = 'text/plain' }
    UserAgent = "ChangeMe"  # See warning above!
}

Invoke-RestMethod @ApiParams
```

You should see a classic Dad joke, like:  
`What did the Red light say to the Green light? Don't look at me, I'm changing!`

* * *

## Step 2: Make it Reusable – Wrap It in a Function!

Let's make this a function so you can call it anytime.

```powershell
function Get-DadJoke {
    $ApiParams = @{
        URI       = 'https://icanhazdadjoke.com/'
        Headers   = @{ accept = 'text/plain' }
        UserAgent = "ChangeMe" # ← Change this!
    }
    Invoke-RestMethod @ApiParams
}
```

Functions in PowerShell start with `Verb-Noun` (but you can pick any names you want).  
Now just run:

```powershell
Get-DadJoke
```

> I've got a joke about vegetables for you... but it's a bit corny.
{: .prompt-info }

Each time you run this, you’ll get a new random joke! 🎲

* * *

## Step 3: Add Search Capability

Maybe you want a joke for a specific occasion or topic—like, say, _scarecrows_?  
Let's upgrade our function so you can search for any word or theme you want by using a `-Search` parameter.

> Don't forget to set a real UserAgent in every example—it's required!
{: .prompt-danger }

```powershell
function Get-DadJoke {
    param(
        [string]$Search
    )

    if ($Search) {
        $URI = "https://icanhazdadjoke.com/search?term=$Search"
    } else {
        $URI = 'https://icanhazdadjoke.com/'
    }

    $ApiParams = @{
        URI       = $URI
        Headers   = @{ accept = 'text/plain' }
        UserAgent = "ChangeMe" # ← Change this!
    }

    Invoke-RestMethod @ApiParams
}
```

Try it out:

```powershell
Get-DadJoke -Search scarecrow
```

> Why did the scarecrow win an award? Because he was outstanding in his field.
{: .prompt-info }

> We added a `-Search` parameter, and according to the [API docs](https://icanhazdadjoke.com/api), we simply create a new URI using the string you input for custom joke searches!
{: .prompt-tip }

## Step 4: Suggest More Fun! (Optional)

Wouldn't it be even more fun if PowerShell could **read the joke aloud**?  
We will add a switch called `-Audio` to do just that!  
Here’s how you might do it (Windows only):

```powershell
function Get-DadJoke {
    param(
        [string]$Search,
        [switch]$Audio
    )

    if ($Search) {
        $URI = "https://icanhazdadjoke.com/search?term=$Search"
    } else {
        $URI = 'https://icanhazdadjoke.com/'
    }

    $ApiParams = @{
        URI       = $URI
        Headers   = @{ accept = 'text/plain' }
        UserAgent = "ChangeMe" # ← Change this!
    }

    $DadJoke = Invoke-RestMethod @ApiParams
    $DadJoke
    if ($Audio){
        $sp = New-Object -ComObject SAPI.SpVoice
        $sp.Speak($DadJoke) | Out-Null
    }
}
```

Call it:

```powershell
Get-DadJoke -Audio
```

> **What changed in this step?**
> We introduced the `[switch]$Audio` parameter. Now, if you run the function with `-Audio`, PowerShell will use Windows' built-in speech engine to read your joke out loud!
> The magic happens with these lines:
> 
> ```powershell
> $sp = New-Object -ComObject SAPI.SpVoice
> $sp.Speak($DadJoke) | Out-Null
> ```
> 
> This creates a speech synthesizer and sends your joke to it, so you (and anyone nearby) can enjoy a random dad joke with your ears, not just your eyes!
{: .prompt-tip }

* * *

## Step 5: Level Up Further (Optional)

Want to go wild?  
How about customizing the voice, speed, and volume? (Because why not? 😎)

```powershell
function Get-DadJoke {
    param(
        [string]$Search,
        [switch]$Audio,
        [int]$VoiceIndex = 0,
        [int]$Rate = 0,
        [int]$Volume = 100
    )

    if ($Search) {
        $URI = "https://icanhazdadjoke.com/search?term=$Search"
    } else {
        $URI = 'https://icanhazdadjoke.com/'
    }

    $ApiParams = @{
        URI       = $URI
        Headers   = @{ accept = 'text/plain' }
        UserAgent = "ChangeMe" # ← Change this!
    }

    $DadJoke = Invoke-RestMethod @ApiParams
    $output = $DadJoke
    # If search, API returns an object with results
    if ($Search -and $DadJoke.results) {
        if ($DadJoke.results.Count -gt 0) {
            $output = $DadJoke.results[0].joke
        } else {
            $output = "No jokes found for '$Search'."
        }
    }
    $output
    if ($Audio) {
        $sp = New-Object -ComObject SAPI.SpVoice
        $voices = $sp.GetVoices()
        if ($VoiceIndex -ge 0 -and $VoiceIndex -lt $voices.Count) {
            $sp.Voice = $voices.Item($VoiceIndex)
        }
        $sp.Rate = [Math]::Max(-10, [Math]::Min(10, $Rate))
        $sp.Volume = [Math]::Max(0, [Math]::Min(100, $Volume))
        $sp.Speak($output) | Out-Null
    }
}
```

Try all the bells and whistles:

```powershell
Get-DadJoke -Audio -VoiceIndex 1 -Rate 2 -Volume 80
```

* * *

## That's a Wrap!

Congratulations, you've built a **fully loaded, over-engineered** Dad Joke function in PowerShell!  
Share it with friends, or better yet, add your own twists.  
Happy scripting!

* * *