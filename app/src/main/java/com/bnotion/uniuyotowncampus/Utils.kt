package com.bnotion.uniuyotowncampus

import android.app.Activity
import android.content.Context
import android.view.inputmethod.InputMethodManager

object Utils {
    @JvmStatic
    fun hideKeyboard(activity: Activity) {
        try {
            val imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            activity.currentFocus?.let {
                imm.hideSoftInputFromWindow(it.windowToken, 0)
            }
        } catch (e: Exception) {
            // Ignore
        }
    }
}
