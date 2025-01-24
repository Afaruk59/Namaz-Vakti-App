package com.afaruk59.namaz_vakti_app;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Calendar;
import android.os.AsyncTask;
import android.util.Log;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserFactory;

import com.afaruk59.namaz_vakti_app.R;

public class PrayerTimesWidget extends AppWidgetProvider {

    private static final String PREFS_NAME = "FlutterSharedPreferences";
    private static final String BASE_URL = "https://www.namazvakti.com/XML.php?cityID=";

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    @Override
    public void onEnabled(Context context) {
        // Widget ilk kez eklendiğinde çağrılır
        super.onEnabled(context);
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
        int[] appWidgetIds = appWidgetManager.getAppWidgetIds(new android.content.ComponentName(context, PrayerTimesWidget.class));
        onUpdate(context, appWidgetManager, appWidgetIds);
    }

    @Override
    public void onDisabled(Context context) {
        // Son widget kaldırıldığında çağrılır
        super.onDisabled(context);
    }

    private static String getFormattedDateTime(Context context) {
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd.MM.yyyy", Locale.getDefault());
        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm", Locale.getDefault());
        Date now = new Date();
        return context.getString(R.string.last_update, timeFormat.format(now) + " | " + dateFormat.format(now));
    }

    static void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        try {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);
            
            // Bugünün tarihini al
            Calendar calendar = Calendar.getInstance();
            final int currentDay = calendar.get(Calendar.DAY_OF_MONTH);
            final int currentMonth = calendar.get(Calendar.MONTH) + 1; // Ocak = 0 olduğu için +1 ekliyoruz
            
            // SharedPreferences'dan location ID ve şehir adını al
            SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            String locationId = prefs.getString("flutter.location", "");
            String cityName = prefs.getString("flutter.name", context.getString(R.string.app_name));
            
            // Widget başlığını şehir adı ile güncelle
            views.setTextViewText(R.id.widgetTitle, cityName);
            
            System.out.println("Location ID: " + locationId);
            System.out.println("City Name: " + cityName);
            System.out.println("Current Date: " + currentDay + "/" + currentMonth);
            
            if (!locationId.isEmpty()) {
                // API'den verileri al
                new AsyncTask<String, Void, String[]>() {
                    @Override
                    protected String[] doInBackground(String... params) {
                        try {
                            URL url = new URL(BASE_URL + locationId);
                            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                            connection.setRequestMethod("GET");
                            
                            BufferedReader reader = new BufferedReader(
                                new InputStreamReader(connection.getInputStream())
                            );
                            
                            StringBuilder response = new StringBuilder();
                            String line;
                            while ((line = reader.readLine()) != null) {
                                response.append(line);
                            }
                            reader.close();

                            // XML'i parse et
                            XmlPullParserFactory factory = XmlPullParserFactory.newInstance();
                            XmlPullParser parser = factory.newPullParser();
                            parser.setInput(new StringReader(response.toString()));

                            String[] times = null;
                            int eventType = parser.getEventType();
                            
                            while (eventType != XmlPullParser.END_DOCUMENT) {
                                if (eventType == XmlPullParser.START_TAG && parser.getName().equals("prayertimes")) {
                                    // prayertimes elementinin day ve month attribute'larını kontrol et
                                    String dayStr = parser.getAttributeValue(null, "day");
                                    String monthStr = parser.getAttributeValue(null, "month");
                                    
                                    if (dayStr != null && monthStr != null) {
                                        int day = Integer.parseInt(dayStr);
                                        int month = Integer.parseInt(monthStr);
                                        
                                        if (day == currentDay && month == currentMonth) {
                                            // Bugünün verilerini bulduk
                                            parser.next();
                                            if (parser.getEventType() == XmlPullParser.TEXT) {
                                                String text = parser.getText().trim();
                                                times = text.split("\\s+");
                                                break;
                                            }
                                        }
                                    }
                                }
                                eventType = parser.next();
                            }
                            
                            if (times == null) {
                                Log.d("PrayerTimesWidget", "No data found for date: " + currentDay + "/" + currentMonth);
                            }
                            
                            return times;
                            
                        } catch (Exception e) {
                            Log.e("PrayerTimesWidget", "Error fetching data", e);
                            e.printStackTrace();
                            return null;
                        }
                    }
                    
                    @Override
                    protected void onPostExecute(String[] times) {
                        if (times != null && times.length > 13) {
                            try {
                                // Flutter kodundaki sıralamaya göre vakitleri al
                                String imsak = times[0];
                                String gunes = times[2];
                                String ogle = times[5];
                                String ikindi = times[6];
                                String aksam = times[9];
                                String yatsi = times[11];

                                // Vakitleri widget'a yerleştir
                                views.setTextViewText(R.id.imsakTime, imsak);
                                views.setTextViewText(R.id.gunesTime, gunes);
                                views.setTextViewText(R.id.ogleTime, ogle);
                                views.setTextViewText(R.id.ikindiTime, ikindi);
                                views.setTextViewText(R.id.aksamTime, aksam);
                                views.setTextViewText(R.id.yatsiTime, yatsi);
                                
                                // Son güncelleme zamanını tarih ve saat olarak ayarla
                                views.setTextViewText(R.id.lastUpdate, getFormattedDateTime(context));
                                
                                // Widget'ı güncelle
                                appWidgetManager.updateAppWidget(appWidgetId, views);
                            } catch (Exception e) {
                                Log.e("PrayerTimesWidget", "Error parsing data", e);
                                setDefaultTimes(context, views, appWidgetManager, appWidgetId);
                            }
                        } else {
                            Log.d("PrayerTimesWidget", "Invalid data format or no data received");
                            setDefaultTimes(context, views, appWidgetManager, appWidgetId);
                        }
                    }
                }.execute();
            } else {
                // Location ID bulunamadıysa varsayılan değerleri göster
                setDefaultTimes(context, views, appWidgetManager, appWidgetId);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void setDefaultTimes(Context context, RemoteViews views, AppWidgetManager appWidgetManager, int appWidgetId) {
        // SharedPreferences'dan şehir adını al (varsayılan değerler için de)
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        String cityName = prefs.getString("flutter.name", context.getString(R.string.app_name));
        views.setTextViewText(R.id.widgetTitle, cityName);

        views.setTextViewText(R.id.imsakTime, "00:00");
        views.setTextViewText(R.id.gunesTime, "00:00");
        views.setTextViewText(R.id.ogleTime, "00:00");
        views.setTextViewText(R.id.ikindiTime, "00:00");
        views.setTextViewText(R.id.aksamTime, "00:00");
        views.setTextViewText(R.id.yatsiTime, "00:00");

        // Son güncelleme zamanını tarih ve saat olarak ayarla
        views.setTextViewText(R.id.lastUpdate, getFormattedDateTime(context));
        
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
} 