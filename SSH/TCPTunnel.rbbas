#tag Class
Protected Class TCPTunnel
Inherits SSH.Channel
	#tag Event
		Sub DataAvailable(ExtendedStream As Boolean)
		  #pragma Unused ExtendedStream
		  RaiseEvent DataAvailable()
		End Sub
	#tag EndEvent

	#tag Event
		Sub Disconnected()
		  RaiseEvent Disconnected()
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error(Reasons As Integer)
		  RaiseEvent Error(Reasons)
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Close()
		  If IsOpen Then
		    Super.Close()
		    RaiseEvent Disconnected()
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Function Connect() As Boolean
		  ' Initiates an outbound TCP connection to RemoteAddress:RemotePort via the SSH server.
		  ' If the connection was successful the Connected() event will be raised and this
		  ' method returns True. Otherwise, the Error() event will be raised.
		  ' Once connected you may read and write to the tunnel like any other Channel.
		  
		  If IsOpen Then Return True
		  If Not Session.IsAuthenticated Then Raise New SSHException(ERR_NOT_AUTHENTICATED)
		  
		  Dim p As Ptr
		  p = libssh2_channel_direct_tcpip_ex(Session.Handle, RemoteAddress, RemotePort, LocalInterface.IPAddress, LocalPort)
		  If p <> Nil Then
		    Super.Constructor(mSession, p)
		    RaiseEvent Connected()
		    Return True
		  Else
		    mLastError = Session.LastError
		    RaiseEvent Error(mLastError)
		  End If
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor(Session As SSH.Session)
		  ' Construct a new unconnected tunnel.
		  ' The Session need not yet be connected or authenticated.
		  mSession = Session
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Flush()
		  Super.Flush(0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  Return Super.Read(Count, 0, encoding)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(text As String)
		  Super.Write(text, 0)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataAvailable()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Disconnected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(Reasons As Integer)
	#tag EndHook


	#tag Note, Name = About this class
		This class is for intitiating an outbound connection from the client to a third party, using the SSH server as an intermediary.
		
		For example, this forwards an HTTP request through the SSH server to google.com:
		
		  Dim tunnel As New SSH.TCPTunnel(Session)
		  tunnel.RemoteAddress = "www.google.com"
		  tunnel.RemotePort = 80
		  If Not tunnel.Connect() Then
		    MsgBox("Unable to open tunnel.")
		  End If
		
		  // write to the tunnel
		  Dim crlf As String = EndOfLine.Windows
		  tunnel.Write( _
		     "GET / HTTP/1.0" + crlf + _
		     "Host: www.google.com" + crlf + _
		     "Connection: close" + crlf + crlf)
		  
		  // read from the tunnel
		  Dim output As String
		  Do Until tunnel.EOF
		    If tunnel.PollReadable() Then
		      output = output + tunnel.Read(tunnel.BytesReadable)
		    End If
		  Loop
	#tag EndNote


	#tag ComputedProperty, Flags = &h0
		#tag Note
			The local NetworkInterface that is initiating the outbound connection. 
			If this property is not set to a custom value then Session.NetworkInterface
			is used. The LocalInterface need not refer to the same interface that the 
			SSH session is using.
		#tag EndNote
		#tag Getter
			Get
			  If mLocalInterface = Nil Then mLocalInterface = mSession.NetworkInterface
			  return mLocalInterface
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not IsOpen Then mLocalInterface = value
			End Set
		#tag EndSetter
		LocalInterface As NetworkInterface
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Note
			The local port number that is initiating the outbound connection.
			If this property is not set to a custom value then a random ephemeral
			port is used. The local port number need not actually be available.
		#tag EndNote
		#tag Getter
			Get
			  If mLocalPort <= 0 Then
			    Dim r As New Random
			    mLocalPort = r.InRange(4096, 65534)
			  End If
			  return mLocalPort
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not IsOpen Then mLocalPort = value
			End Set
		#tag EndSetter
		LocalPort As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mLocalInterface As NetworkInterface
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLocalPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemoteAddress As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRemotePort As Integer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Note
			The hostname or IP address of the third-party server we want the SSH server
			to open a connection to. If a hostname is provided the SSH server will 
			resolve it to an IP according to its own DNS configuration.
		#tag EndNote
		#tag Getter
			Get
			  return mRemoteAddress
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not IsOpen Then mRemoteAddress = value
			End Set
		#tag EndSetter
		RemoteAddress As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Note
			The port number on the third-party server we want the SSH server to open a connection to.
		#tag EndNote
		#tag Getter
			Get
			  return mRemotePort
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Not IsOpen Then mRemotePort = value
			End Set
		#tag EndSetter
		RemotePort As Integer
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="ExitStatus"
			Group="Behavior"
			Type="Integer"
			InheritedFrom="SSH.Channel"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsOpen"
			Group="Behavior"
			Type="Boolean"
			InheritedFrom="SSH.Channel"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LocalPort"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemoteAddress"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemotePort"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass