package com.example.task_bell

import android.media.RingtoneManager
import android.os.Bundle
import android.database.Cursor
import io.flutter.plugin.common.MethodChannel

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.task_bell.ringtones";

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getRingtones") {
                val ringtones = getRingtones()
                result.success(ringtones)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getRingtones() : List<String> {
        val ringtonePaths = mutableListOf<String>()
        val ringtoneManager = RingtoneManager(this)
        ringtoneManager.setType(RingtoneManager.TYPE_RINGTONE)

        val cursor: Cursor? = ringtoneManager.cursor
        cursor?.let {
            if (it.moveToFirst()) {
                do {
                    // val ringtoneUriString = it.getString(it.getColumnIndex(RingtoneManager.URI_COLUMN_INDEX))
                    // ringtonePaths.add(ringtoneUriString)
                    ringtonePaths.add(it.getString(RingtoneManager.URI_COLUMN_INDEX) + "/" + 
                        it.getString(RingtoneManager.ID_COLUMN_INDEX));
                } while (it.moveToNext())
            }
            it.close()
        }

        return ringtonePaths
    }

}
