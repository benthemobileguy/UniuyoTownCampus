package com.bnotion.uniuyotowncampus;

import android.content.Intent;
import android.content.pm.ActivityInfo;
import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.os.Handler;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;
import android.widget.TextView;

public class SplashActivity extends AppCompatActivity {
    public static int SPLASH_TIME_OUT = 8000;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // locking out landscape screen orientation for mobiles
        if(getResources().getBoolean(R.bool.portrait_only)){
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            // locking out portait screen orientation for tablets
        } if(getResources().getBoolean(R.bool.landscape_only)) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        }
        setContentView(R.layout.activity_splash);
        ImageView imageView = findViewById(R.id.img_logo);
        TextView textView = findViewById(R.id.app_text);
        Animation myFadeInAnimation = AnimationUtils.loadAnimation(this, R.anim.fade_in_splash);
        imageView.startAnimation(myFadeInAnimation);
        textView.startAnimation(myFadeInAnimation);
        new Handler().postDelayed(new Runnable() {

            @Override
            public void run() {
                launchMain();
            }
        }, SPLASH_TIME_OUT);
    }


    private void launchMain() {
        Intent intent = new Intent(this,MainActivity.class);
        startActivity(intent);
        finish();
        overridePendingTransition(R.anim.slide_in_left, R.anim.slide_in_right);
    }
}