package com.bnotion.uniuyotowncampus

import android.content.Intent
import android.content.pm.ActivityInfo
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.cardview.widget.CardView

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Lock screen orientation
        if (resources.getBoolean(R.bool.portrait_only)) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
        if (resources.getBoolean(R.bool.landscape_only)) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        }

        setContentView(R.layout.activity_main)

        val directionsCard: CardView = findViewById(R.id.directions)
        val searchCard: CardView = findViewById(R.id.search)
        val notificationsCard: CardView = findViewById(R.id.notifications)
        val studySpaceCard: CardView = findViewById(R.id.study_space)
        val feedbackCard: CardView = findViewById(R.id.feedback)
        val campusInfoCard: CardView = findViewById(R.id.campus_info)

        directionsCard.setOnClickListener {
            startActivity(Intent(this, DirectionsActivity::class.java))
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
        }

        searchCard.setOnClickListener {
            startActivity(Intent(this, SearchActivity::class.java))
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
        }

        notificationsCard.setOnClickListener {
            startActivity(Intent(this, NotificationsActivity::class.java))
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
        }

        studySpaceCard.setOnClickListener {
            startActivity(Intent(this, StudySpaceActivity::class.java))
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
        }

        feedbackCard.setOnClickListener {
            try {
                val uriText = "mailto:bnotionsoftware@gmail.com" +
                        "?subject=${Uri.encode("Feedback for app")}" +
                        "&body=${Uri.encode("info")}"
                val uri = Uri.parse(uriText)
                val emailIntent = Intent(Intent.ACTION_SENDTO).apply {
                    data = uri
                }
                startActivity(Intent.createChooser(emailIntent, "Send email using..."))
            } catch (ex: android.content.ActivityNotFoundException) {
                Toast.makeText(this, "No email clients installed.", Toast.LENGTH_SHORT).show()
            }
        }

        campusInfoCard.setOnClickListener {
            startActivity(Intent(this, CampusInfoActivity::class.java))
            overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
        }
    }
}
