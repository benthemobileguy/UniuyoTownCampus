package com.bnotion.uniuyotowncampus;

import android.app.Activity;
import android.content.Context;
import android.view.inputmethod.InputMethodManager;

public class Utils {


    public static void hideKeyboard(Activity activity)   {
        try {
            InputMethodManager inputmanager = (InputMethodManager) activity.getSystemService(Context.INPUT_METHOD_SERVICE);
            if (inputmanager != null) {
                inputmanager.hideSoftInputFromWindow(activity.getCurrentFocus().getWindowToken(), 0);
            }
        } catch (Exception var2) {
        }

    }
}
