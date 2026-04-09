import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

# 1. Load the data
# Change 'pi_metrics.csv' to your actual file name
df = pd.read_csv('terraform/workstation_metrics.csv', comment='#')

# 2. Convert the 'Timestamp' column to actual datetime objects
# This ensures matplotlib formats the X-axis time intervals cleanly
df['Timestamp'] = pd.to_datetime(df['Timestamp'], format='%H:%M:%S')

# ==========================================
# Graph 1: CPU Utilization
# ==========================================
plt.figure(figsize=(10, 4)) # Width, Height in inches
plt.plot(df['Timestamp'], df['CPU_%'], color='tab:blue', linewidth=1.5)

plt.title('Edge Node CPU Utilization over Time', fontsize=14)
plt.xlabel('Time (HH:MM:SS)', fontsize=12)
plt.ylabel('CPU Usage (%)', fontsize=12)

# Format the X-axis to show clean time labels
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
plt.grid(True, linestyle='--', alpha=0.7)

# Save the plot as a high-res image for your paper
plt.tight_layout()
plt.savefig('cpu_utilization_graph.png', dpi=300)
plt.close() # Close the figure to save memory

# ==========================================
# Graph 2: Memory Usage
# ==========================================
plt.figure(figsize=(10, 4))
plt.plot(df['Timestamp'], df['Mem_Used_MB'], color='tab:orange', linewidth=1.5)

plt.title('Edge Node Memory Usage over Time', fontsize=14)
plt.xlabel('Time (HH:MM:SS)', fontsize=12)
plt.ylabel('Memory Used (MB)', fontsize=12)

plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
plt.grid(True, linestyle='--', alpha=0.7)

plt.tight_layout()
plt.savefig('memory_usage_graph.png', dpi=300)
plt.close()

print("Graphs successfully generated and saved as PNG files!")