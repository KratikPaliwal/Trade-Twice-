package com.sidlatau.flutteremailsender

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

import android.content.ClipData
import android.content.ClipDescription
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.core.text.HtmlCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File

private const val SUBJECT = "subject"
private const val BODY = "body"
private const val RECIPIENTS = "recipients"
private const val CC = "cc"
private const val BCC = "bcc"
private const val ATTACHMENT_PATHS = "attachment_paths"
private const val IS_HTML = "is_html"
private const val REQUEST_CODE_SEND = 607

class FlutterEmailSenderPlugin
    : FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {
    companion object {

        private const val methodChannelName = "flutter_email_sender"

        var activity: Activity? = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, methodChannelName)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
        activityPluginBinding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
        activityPluginBinding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private var channelResult: Result? = null

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "send") {
            // If the call threw an exception, Flutter already sent a result to the channel,
            // so we don't need to send a result from onActivityResult anymore.
            this.channelResult = result
            sendEmail(call, result)
        } else {
            result.notImplemented()
        }
    }

    private fun sendEmail(options: MethodCall, callback: Result) {
        if (activity == null) {
            callback.error("error", "Activity == null!", null)
            return
        }

        val body = options.argument<String>(BODY)
        val isHtml = options.argument<Boolean>(IS_HTML) ?: false
        val attachmentPaths = options.argument<ArrayList<String>>(ATTACHMENT_PATHS) ?: ArrayList()
        val subject = options.argument<String>(SUBJECT)
        val recipients = options.argument<ArrayList<String>>(RECIPIENTS)
        val cc = options.argument<ArrayList<String>>(CC)
        val bcc = options.argument<ArrayList<String>>(BCC)

        var text: CharSequence? = null
        var html: String? = null
        if (body != null) {
            if (isHtml) {
                text = HtmlCompat.fromHtml(body, HtmlCompat.FROM_HTML_MODE_LEGACY)
                html = body
            } else {
                text = body
            }
        }
        val attachmentUris = attachmentPaths.map {
            FileProvider.getUriForFile(activity!!, activity!!.packageName + ".file_provider", File(it))
        }

        val intent = Intent()

        // We need a different intent action depending on the number of attachments.
        if (attachmentUris.isEmpty()) {
            intent.action = Intent.ACTION_SENDTO
            intent.data = Uri.parse("mailto:")
        } else {
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            if (attachmentUris.size == 1) {
                intent.action = Intent.ACTION_SENDTO
                intent.data = Uri.parse("mailto:")
                intent.putExtra(Intent.EXTRA_STREAM, attachmentUris.first())
                // Add a selector intent to make sure that only email apps are shown, instead of just any app that can
                // handle the attached file(s). This is done because the intent data is ignored for ACTION_SEND and
                // ACTION_SEND_MULTIPLE. See: https://stackoverflow.com/a/42856166/14637
                intent.selector = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))

                // From the ACTION_SEND_MULTIPLE docs:
                // "This allows you to use FLAG_GRANT_READ_URI_PERMISSION when sharing content: URIs [...] If you don't set
                // a ClipData, it will be copied there for you when calling Context#startActivity(Intent)."
                // However, this doesn't always seem to be happening, so we have to do the dirty work ourselves.
                val clipItems = attachmentUris.map { ClipData.Item(it) }
                val clipDescription = ClipDescription("", arrayOf("application/octet-stream"))
                val clipData = ClipData(clipDescription, clipItems.first())
                for (item in clipItems.drop(1)) {
                    clipData.addItem(item)
                }
                intent.clipData = clipData
            } else {
                intent.action = Intent.ACTION_SEND_MULTIPLE
                intent.type = "text/plain";
                intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(attachmentUris))
            }
        }

        if (text != null) {
            intent.putExtra(Intent.EXTRA_TEXT, text)
        }

        if (html != null) {
            intent.putExtra(Intent.EXTRA_HTML_TEXT, html)
        }

        if (subject != null) {
            intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        }

        if (recipients != null) {
            intent.putExtra(Intent.EXTRA_EMAIL, listArrayToArray(recipients))
        }

        if (cc != null) {
            intent.putExtra(Intent.EXTRA_CC, listArrayToArray(cc))
        }

        if (bcc != null) {
            intent.putExtra(Intent.EXTRA_BCC, listArrayToArray(bcc))
        }

        val packageManager = activity?.packageManager

        if (packageManager?.resolveActivity(intent, 0) != null) {
            activity?.startActivityForResult(intent, REQUEST_CODE_SEND)
        } else {
            callback.error("not_available", "No email clients found!", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQUEST_CODE_SEND -> {
                channelResult?.success(null)
                channelResult = null
                return true
            }
            else -> {
                false
            }
        }
    }

    private fun listArrayToArray(r: ArrayList<String>): Array<String> {
        return r.toArray(arrayOfNulls<String>(r.size))
    }
}
