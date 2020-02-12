package com.bnotion.uniuyotowncampus;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

public class MainActivity extends AppCompatActivity {
private CardView mDirections, mSearch, mNotifications, mStudySpace, mFeedback, mCampusInfo;

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
        setContentView(R.layout.activity_main);
        mDirections = findViewById(R.id.directions);
        mSearch = findViewById(R.id.search);
        mNotifications = findViewById(R.id.notifications);
        mStudySpace = findViewById(R.id.study_space);
        mFeedback = findViewById(R.id.feedback);
        mCampusInfo = findViewById(R.id.campus_info);
        mDirections.setOnClickListener(v -> {
            Intent intent = new Intent(MainActivity.this, DirectionsActivity.class);
            startActivity(intent);
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out);
        });
        mSearch.setOnClickListener(v -> {
            Intent intent = new Intent(MainActivity.this, SearchActivity.class);
            startActivity(intent);
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out);
        });
        mNotifications.setOnClickListener(v -> {
            Intent intent = new Intent(MainActivity.this, NotificationsActivity.class);
            startActivity(intent);
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out);
        });
        mStudySpace.setOnClickListener(v -> {
            Intent intent = new Intent(MainActivity.this, StudySpaceActivity.class);
            startActivity(intent);
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out);
        });
        mFeedback.setOnClickListener(v -> {
            try {
                String uriText =
                        "mailto:bnotionsoftware@gmail.com" +
                                "?subject=" + Uri.encode("Feedback for app") +
                                "&body=" + Uri.encode("info");
                Uri uri = Uri.parse(uriText);
                Intent emailIntent = new Intent(Intent.ACTION_SENDTO);
                emailIntent.setData(uri);
                startActivity(Intent.createChooser(emailIntent, "Send email using..."));
            } catch (android.content.ActivityNotFoundException ex) {
                Toast.makeText(MainActivity.this, "No email clients installed.", Toast.LENGTH_SHORT).show();
            }
        });
        mCampusInfo.setOnClickListener(v -> {
            Intent intent = new Intent(MainActivity.this, CampusInfoActivity.class);
            startActivity(intent);
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out);
        });
    }
}
